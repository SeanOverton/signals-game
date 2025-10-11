-- audioManager.lua
local audioManager = {}


local sounds = {}
local musics = {}
local dynamicSounds = {}
local activeDynamics = {}

local currentMusic = nil
local musicQueue = {}
local currentMusicIndex = 1
local waitTimer = 0
local isWaiting = false
local minWait = 10  -- minimum wait time in seconds
local maxWait = 20  -- maximum wait time in seconds

function audioManager.load(soundTable, musicTable, dynamicsTable)
  AudioManager.loadSound(soundTable)
  AudioManager.loadMusic(musicTable)
  for name, parts in pairs(dynamicsTable) do
    AudioManager.loadDynamic(name, parts)
  end
end

function audioManager.loadSound(soundTable)
  for name, path in pairs(soundTable) do
    sounds[name] = love.audio.newSource(path, "static")
  end
end

function audioManager.loadMusic(musicTable)
  for name, path in pairs(musicTable) do
    musics[name] = love.audio.newSource(path, "stream")
    musics[name]:setLooping(false)  -- Don't loop individual tracks
  end
end

function audioManager.loadDynamic(name, parts)
  dynamicSounds[name] = {
    fadeIn = love.audio.newSource(parts.fadeIn, "static"),
    loop = love.audio.newSource(parts.loop, "stream"),
    fadeOut = love.audio.newSource(parts.fadeOut, "static"),
    state = "stopped",
    volume = parts.volume or 1.0,
  }

  dynamicSounds[name].loop:setLooping(true)
end

function audioManager.playDynamic(name)
  local track = dynamicTracks[name]
  if not track then return end

  if currentDynamic and currentDynamic ~= track then
    AudioManager.stopDynamic()
  end

  currentDynamic = track
  track.fadeIn:setVolume(track.volume)
  track.loop:setVolume(track.volume)
  track.fadeOut:setVolume(track.volume)

  track.state = "fadingIn"
  track.fadeIn:stop()
  track.fadeIn:play()
end

-- 🆕 Stop dynamic track with fade out
function audioManager.stopDynamic()
  local track = currentDynamic
  if not track or track.state == "stopped" then return end

  if track.state == "looping" then
    track.loop:stop()
  elseif track.state == "fadingIn" then
    track.fadeIn:stop()
  end

  track.state = "fadingOut"
  track.fadeOut:stop()
  track.fadeOut:play()
end


local repeatPlaylist = false

function audioManager.setContinuousPlaylist(trackNames, repeatOpt)
  musicQueue = {}
  for _, name in ipairs(trackNames) do
    if musics[name] then
      table.insert(musicQueue, name)
    end
  end
  currentMusicIndex = 1
  isWaiting = false
  waitTimer = 0
  repeatPlaylist = repeatOpt or false
end

function audioManager.startContinuousMusic()
  if #musicQueue > 0 then
    AudioManager.playMusic(musicQueue[currentMusicIndex])
  end
end

function audioManager.stopContinuousMusic()
  musicQueue = {}
  isWaiting = false
  waitTimer = 0
  repeatPlaylist = false
  AudioManager.stopMusic()
end

function audioManager.setWaitRange(min, max)
  minWait = min
  maxWait = max
end

function audioManager.setRepeatPlaylist(repeatOpt)
  repeatPlaylist = repeatOpt
end

function audioManager.update(dt)
  if #musicQueue > 0 then
    if isWaiting then
      waitTimer = waitTimer - dt
      if waitTimer <= 0 then
        -- Start next track
        isWaiting = false
        currentMusicIndex = currentMusicIndex + 1
        if currentMusicIndex > #musicQueue then
          if repeatPlaylist then
            currentMusicIndex = 1  -- Loop back to first track
          else
            musicQueue = {} -- Stop playlist if not repeating
            return
          end
        end
        AudioManager.playMusic(musicQueue[currentMusicIndex])
      end
    elseif currentMusic and not currentMusic:isPlaying() then
      -- Current track finished, start waiting period
      isWaiting = true
      waitTimer = math.random(minWait, maxWait)
      currentMusic = nil
    end
  end

  for name, d in pairs(activeDynamics) do
    if d.state == "fadingIn" and not d.fadeIn:isPlaying() then
      d.state = "looping"
      d.loop:play()
    elseif d.state == "looping" and not d.loop:isPlaying() then
      d.loop:play()
    elseif d.state == "fadingOut" and not d.fadeOut:isPlaying() then
      d.state = "stopped"
      activeDynamics[name] = nil
    end
  end
end

function audioManager.play(name)
    -- dynamic
  if dynamicSounds[name] then
    local d = dynamicSounds[name]
    if d.state ~= "stopped" then
      AudioManager.stop(name)
    end
    d.state = "fadingIn"
    d.fadeIn:setVolume(d.volume)
    d.loop:setVolume(d.volume)
    d.fadeOut:setVolume(d.volume)
    d.fadeIn:stop()
    d.loop:stop()
    d.fadeOut:stop()
    d.fadeIn:play()
    activeDynamics[name] = d
    return
  end

  -- regular
  local s = sounds[name]
  if s then
    s:stop()
    s:play()
  end
end

function audioManager.playMusic(name)
  if currentMusic then
    currentMusic:stop()
  end
  local music = musics[name]
  if music then
    currentMusic = music
    currentMusic:play()
  end
end

function audioManager.stop(name)
  -- dynamic?
  local d = dynamicSounds[name]
  if d and d.state ~= "stopped" then
    if d.state == "fadingIn" then
      d.fadeIn:stop()
    elseif d.state == "looping" then
      d.loop:stop()
    end
    if d.state == "fadingOut" and d.fadeOut:isPlaying() then
      -- Already fading out, do nothing
      return
    end
    d.state = "fadingOut"
    d.fadeOut:stop()
    d.fadeOut:play()
    activeDynamics[name] = d
    return
  end

  -- regular
  local s = sounds[name]
  if s then s:stop() end
end

function audioManager.isStopping(name)
  local d = dynamicSounds[name]
  if d then
    return d.state == "fadingOut"
  end
  return false
end

function audioManager.stopMusic()
  if currentMusic then
    currentMusic:stop()
  end
end

function audioManager.setVolume(name, vol)
  if sounds[name] then
    sounds[name]:setVolume(vol)
  elseif dynamicSounds[name] then
    local d = dynamicSounds[name]
    d.volume = vol
    d.fadeIn:setVolume(vol)
    d.loop:setVolume(vol)
    d.fadeOut:setVolume(vol)
  end
end

function audioManager.setMusicVolume(volume)
  if currentMusic then
    currentMusic:setVolume(volume)
  end
end

function audioManager.pause(name)
  local sound = sounds[name]
  if sound then
    sound:pause()
  end
end

function audioManager.pauseMusic()
  if currentMusic then
    currentMusic:pause()
  end
end

function audioManager.resume(name)
  local sound = sounds[name]
  if sound then
    sound:play()
  end
end

function audioManager.resumeMusic()
  if currentMusic then
    currentMusic:play()
  end
end

function audioManager.isPlaying(name)
  local sound = sounds[name]
  local dynamic = dynamicSounds[name]
  if dynamic then
    return dynamic.fadeIn:isPlaying() or dynamic.loop:isPlaying() or dynamic.fadeOut:isPlaying()
  end
  return sound and sound:isPlaying()
end

function audioManager.isMusicPlaying()
  return currentMusic and currentMusic:isPlaying()
end

return audioManager