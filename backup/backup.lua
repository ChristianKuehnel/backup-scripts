local backup = {} 

local path = require "pl.path"
local helper = require "backup.helper"
local dir = require "pl.dir"
local Date = require "pl.Date"
local posix = require "posix"


-- Exported functions -------------------------------------
function backup.files(source_url, target_root, exclude)
  dir.makepath(target_root)
  
  now = helper.date_to_string(Date())
  target_path = path.join(target_root,now)
  helper.rsync(source_url,target_path, helper.find_latest(target_root), exclude)
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

function backup.webdav(mount_point, target_dir)
  local prefix = ""
  if posix.getuid() ~= 0 then
    -- if we're not root: execute with sudo
    prefix = 'sudo '
  end
  
  if helper.is_mounted(mount_point) then
    print('warning: folder is already mounted! Unmounting first')
    assert( os.execute(prefix..'umount '..mount_point) )
  end
  assert( os.execute(prefix..'mount '..mount_point) )
  
  backup.files(mount_point,target_dir,{"lost+found"})
  assert( os.execute(prefix..'umount '..mount_point) )
end 


return backup
