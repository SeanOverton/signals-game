-- audioManager.lua
local audioManager = {}

local sounds = {}
local musics = {}
local currentMusic = nil
local musicQueue = {}
local currentMusicIndex = 1
local waitTimer = 0
local isWaiting = false
local minWait = 10  -- minimum wait time in seconds
local maxWait = 20  -- maximum wait time in seconds

function audioManager.load(soundTable)
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
end

function audioManager.play(name)
  local sound = sounds[name]
  if sound then
    sound:stop()
    sound:play()
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
  local sound = sounds[name]
  if sound then
    sound:stop()
  end
end

function audioManager.stopMusic()
  if currentMusic then
    currentMusic:stop()
  end
end

function audioManager.setVolume(name, volume)
  local sound = sounds[name]
  if sound then
    sound:setVolume(volume)
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
  return sound and sound:isPlaying()
end

function audioManager.isMusicPlaying()
  return currentMusic and currentMusic:isPlaying()
end

return audioManager