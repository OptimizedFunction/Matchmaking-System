local module = {}

myTable = {}
table.insert(myTable, "foo")
table.insert(myTable, "bar")

function module.getMyTable()
	return myTable
end

return module