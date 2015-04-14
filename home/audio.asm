; Audio interfaces.

SoundRestart:: ; 3b4e

	push hl
	push de
	push bc
	push af

	ld a, [hROMBank]
	push af
	ld a, BANK(_SoundRestart)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	call _SoundRestart

	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a

	pop af
	pop bc
	pop de
	pop hl
	ret
; 3b6a


UpdateSound:: ; 3b6a

	push hl
	push de
	push bc
	push af

	ld a, [hROMBank]
	push af
	ld a, BANK(_UpdateSound)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	call _UpdateSound

	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a

	pop af
	pop bc
	pop de
	pop hl
	ret
; 3b86


_LoadMusicByte:: ; 3b86
; CurMusicByte = [a:de]
GLOBAL LoadMusicByte

	ld [hROMBank], a
	ld [MBC3RomBank], a

	ld a, [de]
	ld [CurMusicByte], a
	ld a, BANK(LoadMusicByte)

	ld [hROMBank], a
	ld [MBC3RomBank], a
	ret
; 3b97


PlayMusic:: ; 3b97
; Play music de.

	push hl
	push de
	push bc
	push af

	ld a, [hROMBank]
	push af
	ld a, BANK(_PlayMusic) ; and BANK(_SoundRestart)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	ld a, e
	and a
	jr z, .nomusic

	call _PlayMusic
	jr .end

.nomusic
	call _SoundRestart

.end
	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3bbc


PlayMusic2:: ; 3bbc
; Stop playing music, then play music de.

	push hl
	push de
	push bc
	push af

	ld a, [hROMBank]
	push af
	ld a, BANK(_PlayMusic)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	push de
	ld de, MUSIC_NONE
	call _PlayMusic
	call DelayFrame
	pop de
	call _PlayMusic

	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a

	pop af
	pop bc
	pop de
	pop hl
	ret

; 3be3


PlayCryHeader:: ; 3be3
; Play cry header de.

	push hl
	push de
	push bc
	push af

	ld a, [hROMBank]
	push af

	; Cry headers are stuck in one bank.
	ld a, BANK(CryHeaders)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	ld hl, CryHeaders
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	add hl, de
	add hl, de

	ld e, [hl]
	inc hl
	ld d, [hl]
	inc hl

	ld a, [hli]
	ld [CryPitch], a
	ld a, [hli]
	ld [CryPitch + 1], a
	ld a, [hli]
	ld [CryLength], a
	ld a, [hl]
	ld [CryLength + 1], a

	ld a, BANK(_PlayCryHeader)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	call _PlayCryHeader

	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a
	
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3c23


PlaySFX:: ; 3c23
; Play sound effect de.
; Sound effects are ordered by priority (lowest to highest)

	push hl
	push de
	push bc
	push af

	; Is something already playing?
	call CheckSFX
	jr nc, .play

	; Does it have priority?
	ld a, [CurSFX]
	cp e
	jr c, .done

.play
	ld a, [hROMBank]
	push af
	ld a, BANK(_PlaySFX)
	ld [hROMBank], a
	ld [MBC3RomBank], a

	ld a, e
	ld [CurSFX], a
	call _PlaySFX

	pop af
	ld [hROMBank], a
	ld [MBC3RomBank], a

.done
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3c4e


WaitPlaySFX:: ; 3c4e
	call WaitSFX
	call PlaySFX
	ret
; 3c55


WaitSFX:: ; 3c55
; infinite loop until sfx is done playing

	push hl
	
.wait
	ld hl, Channel5Flags
	bit 0, [hl]
	jr nz, .wait
	ld hl, Channel6Flags
	bit 0, [hl]
	jr nz, .wait
	ld hl, Channel7Flags
	bit 0, [hl]
	jr nz, .wait
	ld hl, Channel8Flags
	bit 0, [hl]
	jr nz, .wait
	
	pop hl
	ret
; 3c74

IsSFXPlaying:: ; 3c74
; Return carry if no sound effect is playing.
; The inverse of CheckSFX.
	push hl

	ld hl, Channel5Flags
	bit 0, [hl]
	jr nz, .playing
	ld hl, Channel6Flags
	bit 0, [hl]
	jr nz, .playing
	ld hl, Channel7Flags
	bit 0, [hl]
	jr nz, .playing
	ld hl, Channel8Flags
	bit 0, [hl]
	jr nz, .playing

	pop hl
	scf
	ret

.playing
	pop hl
	and a
	ret
; 3c97

MaxVolume:: ; 3c97
	ld a, $77 ; max
	ld [Volume], a
	ret
; 3c9d

LowVolume:: ; 3c9d
	ld a, $33 ; 40%
	ld [Volume], a
	ret
; 3ca3

VolumeOff:: ; 3ca3
	xor a
	ld [Volume], a
	ret
; 3ca8

Function3ca8:: ; 3ca8
	ld a, 4
	ld [MusicFade], a
	ret
; 3cae

Function3cae:: ; 3cae
	ld a, 4 | 1 << 7
	ld [MusicFade], a
	ret
; 3cb4

SkipMusic:: ; 3cb4
; Skip a frames of music.
	and a
	ret z
	dec a
	call UpdateSound
	jr SkipMusic
; 3cbc

FadeToMapMusic:: ; 3cbc
	push hl
	push de
	push bc
	push af

	call GetMapMusic
	ld a, [wMapMusic]
	cp e
	jr z, .done

	ld a, 8
	ld [MusicFade], a
	ld a, e
	ld [MusicFadeIDLo], a
	ld a, d
	ld [MusicFadeIDHi], a
	ld a, e
	ld [wMapMusic], a

.done
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3cdf

PlayMapMusic:: ; 3cdf
	push hl
	push de
	push bc
	push af

	call GetMapMusic
	ld a, [wMapMusic]
	cp e
	jr z, .done

	push de
	ld de, MUSIC_NONE
	call PlayMusic
	call DelayFrame
	pop de
	ld a, e
	ld [wMapMusic], a
	call PlayMusic

.done
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3d03

EnterMapMusic:: ; 3d03
	push hl
	push de
	push bc
	push af

	xor a
	ld [wc2c1], a
	ld de, MUSIC_BICYCLE
	ld a, [PlayerState]
	cp PLAYER_BIKE
	jr z, .play
	call GetMapMusic
.play
	push de
	ld de, MUSIC_NONE
	call PlayMusic
	call DelayFrame
	pop de

	ld a, e
	ld [wMapMusic], a
	call PlayMusic

	pop af
	pop bc
	pop de
	pop hl
	ret
; 3d2f

Function3d2f:: ; 3d2f
	ld a, [wc2c1]
	and a
	jr z, RestartMapMusic
	xor a
	ld [wMapMusic], a
	ld de, MUSIC_NONE
	call PlayMusic
	call DelayFrame
	xor a
	ld [wc2c1], a
	ret
; 3d47

RestartMapMusic:: ; 3d47
	push hl
	push de
	push bc
	push af
	ld de, MUSIC_NONE
	call PlayMusic
	call DelayFrame
	ld a, [wMapMusic]
	ld e, a
	ld d, 0
	call PlayMusic
	pop af
	pop bc
	pop de
	pop hl
	ret
; 3d62

SpecialMapMusic:: ; 3d62
	ld a, [PlayerState]
	cp PLAYER_SURF
	jr z, .surf
	cp PLAYER_SURF_PIKA
	jr z, .surf

	ld a, [StatusFlags2]
	bit 2, a
	jr nz, .contest

.no
	and a
	ret

.bike
	ld de, MUSIC_BICYCLE
	scf
	ret

.surf
	ld de, MUSIC_SURF
	scf
	ret

.contest
	ld a, [MapGroup]
	cp GROUP_ROUTE_35_NATIONAL_PARK_GATE
	jr nz, .no
	ld a, [MapNumber]
	cp MAP_ROUTE_35_NATIONAL_PARK_GATE
	jr z, .ranking
	cp MAP_ROUTE_36_NATIONAL_PARK_GATE
	jr nz, .no

.ranking
	ld de, MUSIC_BUG_CATCHING_CONTEST_RANKING
	scf
	ret
; 3d97

GetMapMusic:: ; 3d97
	call SpecialMapMusic
	ret c
	call GetMapHeaderMusic
	ret
; 3d9f

Function3d9f:: ; 3d9f
; Places a BCD number at the
; upper center of the screen.
; Unreferenced.
	ld a, $20
	ld [Sprites + $98], a
	ld [Sprites + $9c], a
	ld a, $50
	ld [Sprites + $99], a
	ld a, $58
	ld [Sprites + $9d], a
	xor a
	ld [Sprites + $9b], a
	ld [Sprites + $9f], a
	ld a, [wc296]
	cp $64
	jr nc, .max
	add 1
	daa
	ld b, a
	swap a
	and $f
	add "0"
	ld [Sprites + $9a], a
	ld a, b
	and $f
	add "0"
	ld [Sprites + $9e], a
	ret

.max
	ld a, "9"
	ld [Sprites + $9a], a
	ld [Sprites + $9e], a
	ret
; 3dde

CheckSFX:: ; 3dde
; Return carry if any SFX channels are active.
	ld a, [Channel5Flags]
	bit 0, a
	jr nz, .playing
	ld a, [Channel6Flags]
	bit 0, a
	jr nz, .playing
	ld a, [Channel7Flags]
	bit 0, a
	jr nz, .playing
	ld a, [Channel8Flags]
	bit 0, a
	jr nz, .playing
	and a
	ret
.playing
	scf
	ret
; 3dfe

Function3dfe:: ; 3dfe
	xor a
	ld [Channel5Flags], a
	ld [SoundInput], a
	ld [rNR10], a
	ld [rNR11], a
	ld [rNR12], a
	ld [rNR13], a
	ld [rNR14], a
	ret
; 3e10


ChannelsOff:: ; 3e10
; Quickly turn off music channels
	xor a
	ld [Channel1Flags], a
	ld [Channel2Flags], a
	ld [Channel3Flags], a
	ld [Channel4Flags], a
	ld [SoundInput], a
	ret
; 3e21

SFXChannelsOff:: ; 3e21
; Quickly turn off sound effect channels
	xor a
	ld [Channel5Flags], a
	ld [Channel6Flags], a
	ld [Channel7Flags], a
	ld [Channel8Flags], a
	ld [SoundInput], a
	ret
; 3e32