#!/usr/bin/lua5.2

local luaunit = require("luaunit")
package.path = package.path..(';./?/init.lua')
local helper = require('backup.helper')
local Date = require('pl.Date')
local tablex = require('pl.tablex')
local List = require('pl.List')

--[[
  # dates to be used for testing
  "2013-12-17T12:19:01",
  "2013-12-17T12:42:51",
  "2014-12-17T12:44:49Z",
  "2014-12-18T00:05:26",
  "2015-12-18 07:20:44",
  "2015-12-18T08:07:47",
  "2016-1-18T08:09:00",
  "2016-2-18T08:19:16",
  "2016-3-18T08:19:40",
  "2016-4-18T08:23:48",
  "2016-5-18T08:28:36",
  "2016-6-18T10:57:57",
  "2016-7-19T00:05:26",
  "2016-8-01T00:05:27",
  "2016-9-02T00:05:20",
  "2016-9-05T00:05:20",
  "2016-9-09T00:05:20",
  "2016-9-15T00:05:20",
  "2016-9-17T00:05:20",
  "2016-9-22T00:05:20",
  "2016-9-22T00:06:20",
  "2016-9-22T01:05:20",
  "2016-9-22T02:05:20",
]]

local now_str = "2016-9-22T02:05:20"
local now = Date(2016,09,22,2,5,20)
local day = 24*60*60.0

function contains(table, value)
  return tablex.find(table, value) ~= nil
end

function contains_all(table, values)
  for _,value in ipairs(values) do
    if not contains(table,value) then
      return false
    end
  end
  return true
end 

function contains_none(table, values)
  for _,value in ipairs(values) do
    if contains(table,value) then
      return false
    end
  end
  return true
end 

TestDateParsing = {}

  function TestDateParsing.test_string_to_date()
    d = helper.string_to_date(now_str)
    luaunit.assertNotNil(d)
    luaunit.assertEquals(d:year(),2016)
    luaunit.assertEquals(d:month(),9)
    luaunit.assertEquals(d:day(),22)
    luaunit.assertEquals(d:hour(),2)
    luaunit.assertEquals(d:min(),5)
    luaunit.assertEquals(d:sec(),20)   
  end
  
  function TestDateParsing.test_date_to_string()
    fmt = Date.Format()
    luaunit.assertEquals( fmt:tostring(now) , "2016-09-22 02:05:20")
  end

TestPrune = {}

  function TestPrune.test_spare_young_ones()
    local test_data = {}
    test_data["2016-01-01T12:00:00"] = false
    test_data["2016-01-02T12:00:00"] = false
    test_data["2016-01-03T12:00:00"] = false
    test_data["2016-02-01T12:00:00"] = false
    test_data["2016-03-01T12:00:00"] = true
    test_data["2016-03-02T12:00:00"] = false
    test_data["2016-03-03T12:00:00"] = false
    test_data["2016-04-01T12:00:00"] = false
    test_data["2016-05-01T12:00:00"] = true
    test_data["2016-06-01T12:00:00"] = false
    test_data["2016-07-01T12:00:00"] = true
    test_data["2016-08-01T12:00:00"] = true
    test_data["2016-09-07T12:00:00"] = true
    test_data["2016-09-08T12:00:00"] = false
    test_data["2016-09-09T12:00:00"] = false
    test_data["2016-09-10T12:00:00"] = true
    test_data["2016-09-11T12:00:00"] = false
    test_data["2016-09-12T12:00:00"] = true
    test_data["2016-09-13T12:00:00"] = true
    test_data["2016-09-14T12:00:00"] = true
    test_data["2016-09-15T12:00:00"] = true
    test_data["2016-09-16T12:00:00"] = true
    test_data["2016-09-17T12:00:00"] = true
    test_data["2016-09-18T12:00:00"] = true
    test_data["2016-09-19T12:00:00"] = true
    test_data["2016-09-20T12:00:00"] = true
    test_data["2016-09-20T12:39:00"] = true
    
    local dirs = List(tablex.keys(test_data))

    local young_limit = day * 10
    local old_limit = day * 110
    local young_retention = day
    local old_retention = day * 50 
    local selected = helper.select_for_deletion(dirs,now,young_limit,old_limit,young_retention,old_retention)
    local mismatch = false
    for date,keep in tablex.sort(test_data) do
      local delete = contains(selected,date)
      if delete ~= not keep then
        print('date: '..date..' keep: '..tostring(keep)..' delete : '..tostring(delete))
        mismatch = true
      end
    end
    luaunit.assertFalse(mismatch)
  end

  function TestPrune.test_retention_time()
    days1 = day --1 day
    days10 = 10 * day
    days50 = 50 * day 
    days110 = 110 * day

    young_limit = days10
    old_limit = days110
    young_retention = days1
    old_retention = days50 
    
    -- below or equal young_limit
    luaunit.assertEquals( helper.retention_time(0,young_limit,old_limit,young_retention,old_retention), 0 )
    luaunit.assertEquals( helper.retention_time(10,young_limit,old_limit,young_retention,old_retention), 0 )
    luaunit.assertEquals( helper.retention_time(young_limit,young_limit,old_limit,young_retention,old_retention), 0 )

    -- above or equal old_limit
    luaunit.assertEquals( helper.retention_time(old_limit,young_limit,old_limit,young_retention,old_retention), old_retention )
    luaunit.assertEquals( helper.retention_time(old_limit+50,young_limit,old_limit,young_retention,old_retention), old_retention )

    -- somewhere in between
    luaunit.assertAlmostEquals( helper.retention_time(young_limit+1,young_limit,old_limit,young_retention,old_retention), young_retention, 1 )
    luaunit.assertAlmostEquals( helper.retention_time(old_limit-1,young_limit,old_limit,young_retention,old_retention), old_retention, 1 )
    luaunit.assertAlmostEquals( helper.retention_time(60*day,young_limit,old_limit,young_retention,old_retention), 25.5*day , 1 )
  end    
  

os.exit(luaunit.LuaUnit.run())