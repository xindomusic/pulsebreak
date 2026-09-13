#!/usr/bin/env python3
"""Original layered weapon/impact synthesis. Standard library, deterministic PCM."""
from array import array
from pathlib import Path
import json
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
RNG = random.Random(91326)

def blank(seconds):
    return [0.0] * round(RATE * seconds)

def envelope(t, length, decay=5.0, attack=0.002):
    return min(1.0, t / attack) * math.exp(-decay * t / length) * min(1.0, max(0.0, length - t) / 0.022)

def layer(dst, duration, start=0.0, gain=1.0, freq=150.0, end=None, noise=0.0, decay=5.0, metallic=0.0):
    phase = 0.0
    low = 0.0
    offset = round(start * RATE)
    for i in range(round(duration * RATE)):
        t = i / RATE
        f = freq if end is None else end + (freq - end) * math.exp(-7 * t / duration)
        phase += math.tau * f / RATE
        white = RNG.uniform(-1, 1)
        low += 0.19 * (white - low)
        value = math.sin(phase) * (1-noise) + (white-low)*noise*0.68
        value += metallic * (math.sin(phase*2.731)*0.4 + math.sin(phase*4.119)*0.24)
        at = offset+i
        if at < len(dst): dst[at] += value * gain * envelope(t,duration,decay)

def emit(name, data, peak=0.74):
    dc = sum(data)/len(data)
    gain = peak/max(abs(v-dc) for v in data)
    mono = [(v-dc)*gain for v in data]
    stereo = []
    # Quiet unequal early reflections give width without a moving stereo image.
    for i,v in enumerate(mono):
        left = v*0.90 + (mono[i-441]*0.065 if i>=441 else 0)
        right = v*0.90 + (mono[i-617]*0.065 if i>=617 else 0)
        stereo.extend([left,right])
    pcm = [round(max(-0.95,min(0.95,v))*32767) for v in stereo]
    path=ROOT/'assets/audio'/f'{name}.wav'
    with wave.open(str(path),'wb') as f:
        f.setparams((2,2,RATE,0,'NONE','not compressed'))
        f.writeframes(struct.pack('<'+'h'*len(pcm),*pcm))
    return mono, {'name':name,'seconds':len(data)/RATE,'peak':max(abs(v) for v in stereo),'rms':math.sqrt(sum(v*v for v in stereo)/len(stereo)),'bytes':path.stat().st_size}

def main():
    sounds = {}
    data=blank(.24)
    layer(data,.12,gain=.9,freq=205,end=58,noise=.24)
    layer(data,.038,gain=.54,freq=1650,end=400,noise=.86,decay=6)
    layer(data,.16,.033,.12,880,310,metallic=.6)
    sounds['kinetic_fire']=data
    data=blank(.46)
    layer(data,.27,gain=1.0,freq=170,end=43,noise=.35,decay=4)
    layer(data,.10,gain=.66,freq=1200,end=180,noise=.9)
    layer(data,.17,.15,.22,650,170,noise=.18,metallic=.8)
    sounds['scatter_fire']=data
    data=blank(.39)
    layer(data,.15,gain=.6,freq=260,end=76,noise=.22)
    for i in range(3): layer(data,.22,i*.026,.25,720+i*187,240+i*90,noise=.3,metallic=.35)
    sounds['arc_fire']=data
    data=blank(.68)
    layer(data,.5,gain=.87,freq=195,end=37,noise=.17,decay=4)
    layer(data,.16,gain=.38,freq=930,end=150,noise=.52)
    layer(data,.55,.07,.2,329.63,82.4,metallic=.18,decay=3)
    sounds['plasma_fire']=data
    data=blank(.20)
    layer(data,.085,gain=.8,freq=480,end=110,noise=.72)
    layer(data,.17,.017,.30,1100,500,metallic=.9)
    sounds['armor_impact']=data
    data=blank(.78)
    layer(data,.48,gain=.85,freq=150,end=38,noise=.37,decay=4)
    for t,freq in [(.025,1400),(.13,820),(.23,550)]: layer(data,.28,t,.18,freq,freq*.6,noise=.20,metallic=1.0)
    sounds['machine_break']=data
    data=blank(1.8)
    layer(data,1.35,gain=.9,freq=120,end=31,noise=.40,decay=3.5)
    for t,freq in [(.02,980),(.15,730),(.35,450),(.5,330)]: layer(data,.60,t,.14,freq,freq*.7,metallic=.6)
    sounds['guardian_break']=data
    data=blank(.95)
    for i,freq in enumerate([329.63,493.88,659.25,783.99]): layer(data,.45,i*.095,.3,freq,metallic=.18,decay=4)
    layer(data,.23,gain=.24,freq=130,end=60)
    sounds['weapon_install']=data
    clips={}
    stats=[]
    for name,data in sounds.items():
        clip,stat=emit(name,data,.68 if name=='armor_impact' else .78)
        clips[name]=clip
        stats.append(stat)
    # Fixed, labelled-in-document cue reel: four weapons, impact, breakup, install.
    reel=blank(12.0)
    for time,name in [(0.3,'kinetic_fire'),(.62,'kinetic_fire'),(.94,'kinetic_fire'),(2,'scatter_fire'),(2.85,'scatter_fire'),(4,'arc_fire'),(4.7,'arc_fire'),(6,'plasma_fire'),(7.2,'armor_impact'),(7.7,'machine_break'),(8.7,'guardian_break'),(10.7,'weapon_install')]:
        offset=round(time*RATE)
        for i,value in enumerate(clips[name]):
            if offset+i<len(reel): reel[offset+i]+=value*.72
    path=ROOT/'qa/overdrive-audio-preview.wav'
    with wave.open(str(path),'wb') as f:
        f.setparams((1,2,RATE,0,'NONE','not compressed'))
        f.writeframes(struct.pack('<'+'h'*len(reel),*[round(v*32767) for v in reel]))
    (ROOT/'qa/overdrive-audio.json').write_text(json.dumps({'generator_seed':91326,'rate':RATE,'channels':2,'assets':stats,'preview_order':['carbine x3','scatter x2','arc x2','plasma','armor impact','machine break','guardian break','weapon install'],'audition':'Numeric validation only; listen to preview and full gameplay separately.'},indent=2)+'\n')
    print(f'Generated {len(stats)} original stereo cues and a 12-second cue reel. Maximum peak: {max(x["peak"] for x in stats):.3f}')

if __name__=='__main__': main()
