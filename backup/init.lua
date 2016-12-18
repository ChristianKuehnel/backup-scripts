local backup = {} 

local path = require "pl.path"
local dir = require "pl.dir"
local stringx = require "pl.stringx"

local ISO_DATE_STRING = "!%Y-%m-%dT%TZ"

-- Exported functions -------------------------------------
function backup.files(source_url, target_root)
  dir.makepath(target_root)
  
  now = os.date(ISO_DATE_STRING)
  target_path = path.join(target_root,now)
  rsync(source_url,target_path, find_latest(target_root))
end

function backup.git(server, port, source_dir, target_dir )
  dir.makepath(target_dir)
  
  cmd = string.format('ssh -n %s -p %d ls -1 %s',server,port,source_dir)
  f = assert( io.popen( cmd ) )
  
  for repo in f:lines() do
    full_source = 'ssh://'..server..':'..port..source_dir..'/'..repo 
    full_target = path.join(target_dir, repo)
    if path.isdir(full_target) then
      print('fetching '..full_source..' to '..full_target)
      path.chdir (full_target )
      assert( os.execute('git fetch') )
    else
      print('cloning '..full_source..' to '..full_target)
      path.chdir( target_dir )
      cmd = string.format('git clone --bare '..full_source..' '..repo)
      assert( os.execute(cmd) )         
    end
      
  end
  f:close()
end

-- Helpers --------------------------------------------

function rsync(source_url,target_path,previous_path)
    -- the source_url must end with a '/' otherwise another level of folders will be creted by rsync
    if not stringx.endswith(source_url,'/') then
      source_url = source_url..'/'
    end

    if previous_path == nil then
        print('Running initial rsync from '..source_url..' to '..target_path)
        assert( os.execute('rsync -a '..source_url..' '..target_path) )
    else
        print('Running incremental rsync from '..source_url..' to '..target_path)
        print('Using '..previous_path..' as baseline.')
        assert( os.execute('rsync -a --delete --link-dest='..previous_path..' '..source_url..' '..target_path) )
    end
end

function find_latest(target_root)
  latest = nil  
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


return backup