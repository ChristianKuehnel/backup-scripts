local helper = {}

local path = require "pl.path"
local dir = require "pl.dir"
local stringx = require "pl.stringx"
local posix = require "posix"
local Date = require "pl.Date"
local tablex = require "pl.tablex"
local List = require "pl.List"


local date_format = Date.Format()

function helper.rsync(source_url,target_path,previous_path, exclude)
    -- the source_url must end with a '/' otherwise another level of folders will be creted by rsync
    if not stringx.endswith(source_url,'/') then
      source_url = source_url..'/'
    end

    local exclude_string = " "
    if exclude ~= nil then
      for i,e in ipairs(exclude) do
        exclude_string = exclude_string..' --exclude="'..e..'" '
      end
    end
    
    if previous_path == nil then
        print('Running initial rsync from '..source_url..' to '..target_path)
        local cmd = 'rsync -a '..exclude_string..' "'..source_url..'" "'..target_path..'"'
        assert( os.execute(cmd) )
    else
        print('Running incremental rsync from '..source_url..' to '..target_path)
        print('Using '..previous_path..' as baseline.')
        local cmd = 'rsync -a --delete --link-dest="'..previous_path..'" '..exclude_string..' "'..source_url..'" "'..target_path..'"'
        assert( os.execute(cmd) )
    end
end

function helper.find_latest(target_root)
  local latest = nil  
  for entry in path.dir(target_root) do
    if entry ~= '.' and entry ~= '..' and (latest == nil or entry > latest) then
      latest = entry
    end
  end
  if latest == nil then
    return nil
  end
  return path.join(target_root,latest)
end

function helper.is_mounted(mount_point)
  f = assert( io.open( '/proc/mounts','r' ) )
  for line in f:lines() do

    words = string.gmatch(line, '%S+')
    device = words()
    target = helper.normpath(words())
    if target == helper.normpath(mount_point) then
      return true
    end
  end
  return false
end

function helper.select_for_deletion(dirs,now,young_limit,old_limit,young_retention,old_retention)
  local to_delete = List()
  dirs:sort()
  local last_date = helper.string_to_date(dirs[1]) 
  for current in dirs:iter() do
    local current_date = helper.string_to_date(current)
    local age = now - last_date    
    local retention = Date.Interval( 
      helper.retention_time(age.time,young_limit,old_limit,young_retention,old_retention))
    --print(last_date, retention, current_date)
    if last_date + retention > current_date then
      to_delete:append( current )
    else
      last_date = current_date
    end
  end
  return to_delete
end

--[[
  all parameters are required in seconds, NOT as Interval objects! 
  Interval objects do not support the division operator.
]]
function helper.retention_time(age,young_limit,old_limit,young_retention,old_retention)
  assert(type(age) == "number", "age must be a number")
  assert(type(young_limit) == "number", "young_limit must be a number")
  assert(type(old_limit) == "number", "old_limit must be a number")
  assert(type(young_retention) == "number", "young_retention must be a number")
  assert(type(old_retention) == "number", "old_retention must be a number")
  
  if age <= young_limit then
    return 0
  elseif age >= old_limit then
    return old_retention
  end
  -- linear interpolation of the retention time
  return young_retention+( (old_retention-young_retention)*(age-young_limit)/(old_limit-young_limit) )
end

function helper.normpath(p)
  return path.normpath( path.abspath( p ))
end

function helper.string_to_date(dstr)
  return date_format:parse(tostring(dstr))
end


function helper.date_to_string(d)
  return date_format:tostring(d)
end

return helper
