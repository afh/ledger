import ledger

journal_a = ledger.read_journal("test/input/sample.dat")
journal_b = ledger.read_journal("test/input/drewr3.dat")

xact_a = journal_a.xacts().next()
print xact_a.date # 2003/05/01

xact_b = journal_b.xacts().next()
print xact_b.date # 2010/12/01
