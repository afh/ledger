import ledger

for post in ledger.read_journal('test/regress/xact_code.ledger').query('expenses'):
  print post.xact.code
