-- audioManager.lua
local audioManager = {}


local sounds = {}
local musics = {}
local dynamicSounds = {}
local activeDynamics = {}
local soundTimers = {}

local currentMusic = nil
local musicQueue = {}
local currentMusicIndex = 1
local waitTimer = 0
local isWaiting = false
local minWait = 10  -- minimum wait time in seconds
local maxWait = 20  -- maximum wait time in seconds

function audioManager.load(soundTable, musicTable, dynamicsTable)
  audioManager.loadSound(soundTable)
  audioManager.loadMusic(musicTable)
  if dynamicsTable then
    for name, parts in pairs(dynamicsTable) do
      audioManager.loadDynamic(name, parts)
    end
  end
end

function audioManager.loadSound(soundTable)
  for name, path in pairs(soundTable) do
    if not path.file then
      sounds[name] = {
        audio = love.audio.newSource(path, "static"),
        volume = 1.0,
      }
    else
      sounds[name] = {
        audio = love.audio.newSource(path.file, "static"),
        volume = path.volume or 1.0,
      }
    end
  end
end

function audioManager.loadMusic(musicTable)
  for name, path in pairs(musicTable) do
    musics[name] = love.audio.newSource(path, "stream")
    musics[name]:setLooping(false)  -- Don't loop individual tracks
  end
end

function audioManager.loadDynamic(name, parts)
  local track = {
    loop = love.audio.newSource(parts.loop, "stream"),
    state = "stopped",
    volume = parts.volume or 1.0,
    fadeTimer = 0,
    currentVolume = 0,
  }
  
  track.loop:setLooping(true)
  
  -- Check if using audio file-based fades or duration-based fades
  if parts.fadeIn then
    -- Audio file-based fade in
    track.fadeIn = love.audio.newSource(parts.fadeIn, "static")
    track.useFadeInFile = true
  elseif parts.fadeInDuration then
    -- Duration-based fade in
    track.fadeInDuration = parts.fadeInDuration
    track.useFadeInFile = false
  else
    track.useFadeInFile = false
    track.fadeInDuration = 0
  end
  
  if parts.fadeOut then
    -- Audio file-based fade out
    track.fadeOut = love.audio.newSource(parts.fadeOut, "static")
    track.useFadeOutFile = true
  elseif parts.fadeOutDuration then
    -- Duration-based fade out
    track.fadeOutDuration = parts.fadeOutDuration
    track.useFadeOutFile = false
  else
    track.useFadeOutFile = false
    track.fadeOutDuration = 0
  end
  
  dynamicSounds[name] = track
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
    audioManager.playMusic(musicQueue[currentMusicIndex])
  end
end

function audioManager.stopContinuousMusic()
  musicQueue = {}
  isWaiting = false
  waitTimer = 0
  repeatPlaylist = false
  audioManager.stopMusic()
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
        audioManager.playMusic(musicQueue[currentMusicIndex])
      end
    elseif currentMusic and not currentMusic:isPlaying() then
      -- Current track finished, start waiting period
      isWaiting = true
      waitTimer = math.random(minWait, maxWait)
      currentMusic = nil
    end
  end

  -- Update sound timers
  for name, timer in pairs(soundTimers) do
    timer.elapsed = timer.elapsed + dt
    if timer.elapsed >= timer.duration then
      audioManager.stop(name)
      soundTimers[name] = nil
    end
  end

  -- Update dynamic sounds
  for name, d in pairs(activeDynamics) do
    if d.state == "fadingIn" then
      if d.useFadeInFile then
        -- Audio file-based fade in
        if not d.fadeIn:isPlaying() then
          d.state = "looping"
          d.loop:setVolume(d.volume)
          d.loop:play()
        end
      else
        -- Duration-based fade in
        d.fadeTimer = d.fadeTimer + dt
        if d.fadeInDuration > 0 then
          d.currentVolume = math.min((d.fadeTimer / d.fadeInDuration) * d.volume, d.volume)
          d.loop:setVolume(d.currentVolume)
        else
          d.currentVolume = d.volume
          d.loop:setVolume(d.volume)
        end
        
        if d.fadeTimer >= d.fadeInDuration then
          d.state = "looping"
          d.currentVolume = d.volume
          d.loop:setVolume(d.volume)
        end
      end
    elseif d.state == "looping" then
      if not d.loop:isPlaying() then
        d.loop:play()
      end
    elseif d.state == "fadingOut" then
      if d.useFadeOutFile then
        -- Audio file-based fade out
        if not d.fadeOut:isPlaying() then
          d.state = "stopped"
          activeDynamics[name] = nil
        end
      else
        -- Duration-based fade out
        d.fadeTimer = d.fadeTimer + dt
        if d.fadeOutDuration > 0 then
          d.currentVolume = math.max(d.volume - (d.fadeTimer / d.fadeOutDuration) * d.volume, 0)
          d.loop:setVolume(d.currentVolume)
        else
          d.currentVolume = 0
          d.loop:setVolume(0)
        end
        
        if d.fadeTimer >= d.fadeOutDuration then
          d.loop:stop()
          d.state = "stopped"
          activeDynamics[name] = nil
        end
      end
    end
  end
end

function audioManager.play(name, duration)
  -- dynamic
  if dynamicSounds[name] then
    local d = dynamicSounds[name]
    if d.state ~= "stopped" then
      audioManager.stop(name)
    end
    d.state = "fadingIn"
    d.fadeTimer = 0
    d.currentVolume = 0
    
    if d.useFadeInFile then
      -- Audio file-based fade in
      d.fadeIn:setVolume(d.volume)
      d.loop:setVolume(d.volume)
      d.fadeIn:stop()
      d.loop:stop()
      d.fadeIn:play()
    else
      -- Duration-based fade in
      d.loop:setVolume(0)
      d.loop:stop()
      d.loop:play()
    end
    
    if d.fadeOut then
      d.fadeOut:setVolume(d.volume)
      d.fadeOut:stop()
    end
    
    activeDynamics[name] = d
    
    -- Set up timer if duration is provided
    if duration then
      soundTimers[name] = {
        duration = duration,
        elapsed = 0
      }
    end
    return
  end

  -- regular
  local s = sounds[name]
  if s then
    s.audio:stop()
    s.audio:play()
    
    -- Set up timer if duration is provided
    if duration then
      soundTimers[name] = {
        duration = duration,
        elapsed = 0
      }
    else
      -- Clear any existing timer
      soundTimers[name] = nil
    end
  end
end

function audioManager.playMusic(name)
  if currentMusic then
    currentMusic:stop()
  end
  local music = musics[name]
  if music then
    currentMusic = music
    currentMusic:setVolume(0.3)
    currentMusic:play()
  end
end

function audioManager.stop(name)
  -- Clear timer if exists
  soundTimers[name] = nil
  
  -- dynamic?
  local d = dynamicSounds[name]
  if d and d.state ~= "stopped" then
    if d.state == "fadingOut" then
      -- Already fading out, do nothing
      return
    end
    
    d.state = "fadingOut"
    d.fadeTimer = 0
    
    if d.useFadeOutFile then
      -- Audio file-based fade out
      if d.useFadeInFile and d.fadeIn:isPlaying() then
        d.fadeIn:stop()
      end
      d.loop:stop()
      d.fadeOut:stop()
      d.fadeOut:play()
    else
      -- Duration-based fade out
      d.currentVolume = d.loop:getVolume()
      -- Loop continues playing but will fade out in update()
    end
    
    activeDynamics[name] = d
    return
  end

  -- regular
  local s = sounds[name]
  if s then 
    s.audio:stop() 
  end
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
    sounds[name].volume = vol
  elseif dynamicSounds[name] then
    local d = dynamicSounds[name]
    d.volume = vol
    if d.fadeIn then
      d.fadeIn:setVolume(vol)
    end
    d.loop:setVolume(vol)
    if d.fadeOut then
      d.fadeOut:setVolume(vol)
    end
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
    sound.audio:pause()
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
    sound.audio:play()
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
    if dynamic.useFadeInFile then
      return dynamic.fadeIn and dynamic.fadeIn:isPlaying() or dynamic.loop:isPlaying() or (dynamic.fadeOut and dynamic.fadeOut:isPlaying())
    else
      return dynamic.loop:isPlaying()
    end
  end
  return sound and sound.audio:isPlaying()
end

function audioManager.isMusicPlaying()
  return currentMusic and currentMusic:isPlaying()
end

return audioManager