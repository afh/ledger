import ledger

total = ledger.Balance()

for post in ledger.read_journal("test/baseline/python-checkin.dat").query("^client:"):
    total += post.amount
    begin = post.checkin().to_datetime()
    end   = post.checkout().to_datetime()
    print "%s %8s %s" % (begin.strftime('%Y-%m-%dT%H:%M:%S'), post.amount, post.xact.payee)
    #print end.strftime('%Y-%m-%dT%H:%M:%S')

print "%28s Total" % ( total.to_amount() )
