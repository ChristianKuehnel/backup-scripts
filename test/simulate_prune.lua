#!/usr/bin/lua5.2

package.path = package.path..(';./?/init.lua')
local helper = require('backup.helper')
local Date = require('pl.Date')
local tablex = require('pl.tablex')

local day = 24*3600

function contains(table, value)
  return tablex.find(table, value) ~= nil
end

function print_table( t )
  for k,v in pairs(t) do
    print(k..' : '..v)
  end
end

function simulate_backup_and_pruning()
  local now = Date(2016,1,1,12,0,0)
  local end_date = Date(2018,1,1,12,0,0)
  local date_day = Date.Interval(24*60*60)
  local backups = {}

  local young_limit = day * 10
  local old_limit = day * 110
  local young_retention = day
  local old_retention = day * 50 
  
  while now < end_date do
    backups[#backups+1] = helper.date_to_string(now)
    local to_delete = helper.select_for_deletion(backups,now,young_limit,old_limit,young_retention,old_retention)
    backups = tablex.filter(backups, function(x) return contains(to_delete,x) end)
    print_table(to_delete)
    now = now + date_day
  end
  
  print('Result of backup pruning:')    
  for i=2,(tablex.size(backups)-1) do
    local current = helper.string_to_date(backups[i])
    local last = helper.string_to_date(backups[i-1])
    print(current, current-last)
  end

end

simulate_backup_and_pruning()

