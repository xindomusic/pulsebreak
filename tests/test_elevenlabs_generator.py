"""Offline billing/credential regressions; never read a real key or call an API.

Run: python3 -B -m unittest discover -s tests -p test_elevenlabs_generator.py
"""
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
import urllib.error


SPEC = importlib.util.spec_from_file_location(
    "elevenlabs_generator_under_test",
    Path(__file__).resolve().parents[1] / "tools/generate_elevenlabs_audio.py",
)
GENERATOR = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(GENERATOR)
FAKE_KEY = "dummy-offline-test-credential"


class FakeResponse(io.BytesIO):
    def __init__(self, interrupted=False):
        super().__init__(b"mock audio payload " * 128)
        self.headers = {"Content-Type": "audio/mpeg", "request-id": "mock-request-id"}
        self.interrupted = interrupted

    def read(self, size=-1):
        if self.interrupted:
            raise OSError("Mock interrupted response")
        return super().read(size)


class FakeOpener:
    def __init__(self, interrupted=False, error=None):
        self.calls = 0
        self.interrupted = interrupted
        self.error = error

    def open(self, request, timeout):
        self.calls += 1
        if self.error:
            raise self.error
        return FakeResponse(self.interrupted)


class GenerationSafetyTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="pulsebreak-audio-test-")
        self.addCleanup(self.directory.cleanup)
        self.output = Path(self.directory.name)
        self.output_patch = patch.object(GENERATOR, "OUTPUT", self.output)
        self.output_patch.start()
        self.addCleanup(self.output_patch.stop)
        self.log = io.StringIO()
        self.stdout = contextlib.redirect_stdout(self.log)
        self.stdout.__enter__()
        self.addCleanup(self.stdout.__exit__, None, None, None)
        self.asset = next(item for item in GENERATOR.ASSETS if item["kind"] == "sfx")

    def generate(self, opener, asset=None):
        return GENERATOR.generate(asset or self.asset, FAKE_KEY, opener)

    def receipt(self):
        return json.loads((self.output / (self.asset["name"] + ".json")).read_text())

    def test_default_plan_never_reads_credentials_or_opens_network(self):
        with patch.object(GENERATOR.sys, "argv", ["generate_elevenlabs_audio.py"]), \
                patch.object(GENERATOR, "read_key", side_effect=AssertionError("Key access")), \
                patch.object(GENERATOR.urllib.request, "build_opener", side_effect=AssertionError("Network access")):
            self.assertEqual(GENERATOR.main(), 0)
        self.assertEqual(list(self.output.iterdir()), [])

    def test_completed_download_is_not_charged_again(self):
        opener = FakeOpener()
        self.assertTrue(self.generate(opener))
        self.assertTrue(self.generate(opener))
        self.assertEqual(opener.calls, 1)
        self.assertEqual(self.receipt()["status"], "complete")

    def test_changed_request_does_not_silently_reuse_or_resubmit(self):
        opener = FakeOpener()
        self.assertTrue(self.generate(opener))
        changed = {**self.asset, "body": {**self.asset["body"], "duration_seconds": 1.5}}
        self.assertNotEqual(changed["body"], self.asset["body"])
        self.assertFalse(self.generate(opener, changed))
        self.assertEqual(opener.calls, 1)

    def test_changed_download_does_not_trigger_replacement_request(self):
        opener = FakeOpener()
        self.assertTrue(self.generate(opener))
        (self.output / (self.asset["name"] + ".mp3")).write_bytes(b"modified locally")
        self.assertFalse(self.generate(opener))
        self.assertEqual(opener.calls, 1)

    def test_interruption_retains_recovery_id_and_prevents_resubmission(self):
        opener = FakeOpener(interrupted=True)
        self.assertFalse(self.generate(opener))
        self.assertFalse(self.generate(opener))
        self.assertEqual(opener.calls, 1)
        self.assertEqual(self.receipt()["request-id"], "mock-request-id")
        self.assertEqual(self.receipt()["status"], "interrupted_or_invalid")

    def test_unreceipted_audio_is_never_overwritten_or_resubmitted(self):
        destination = self.output / (self.asset["name"] + ".mp3")
        destination.write_bytes(b"existing audio")
        opener = FakeOpener()
        self.assertFalse(self.generate(opener))
        self.assertEqual(opener.calls, 0)
        self.assertEqual(destination.read_bytes(), b"existing audio")

    def test_provider_error_does_not_expose_key_or_retry(self):
        error = urllib.error.HTTPError(
            "https://api.elevenlabs.io/v1/sound-generation", 401, FAKE_KEY, {},
            io.BytesIO(json.dumps({"detail": {"status": FAKE_KEY}}).encode()),
        )
        opener = FakeOpener(error=error)
        self.assertFalse(self.generate(opener))
        self.assertFalse(self.generate(opener))
        self.assertEqual(opener.calls, 1)
        self.assertNotIn(FAKE_KEY, self.log.getvalue())
        self.assertNotIn(FAKE_KEY, json.dumps(self.receipt()))

    def test_redirect_cannot_forward_credentials(self):
        redirect = GENERATOR.NoRedirect()
        self.assertIsNone(redirect.redirect_request(
            None, None, 302, "Found", {}, "https://unrelated.invalid/collect",
        ))

    def test_oversize_prompt_is_rejected_before_key_access(self):
        invalid = {**self.asset, "body": {**self.asset["body"], "text": "x" * 451}}
        with patch.object(GENERATOR, "ASSETS", [invalid]), \
                patch.object(GENERATOR.sys, "argv", ["generate_elevenlabs_audio.py", "--generate"]), \
                patch.object(GENERATOR, "read_key", side_effect=AssertionError("Key access")), \
                contextlib.redirect_stderr(self.log):
            with self.assertRaises(SystemExit) as stopped:
                GENERATOR.main()
        self.assertEqual(stopped.exception.code, 2)
        self.assertEqual(list(self.output.iterdir()), [])


if __name__ == "__main__":
    unittest.main()
