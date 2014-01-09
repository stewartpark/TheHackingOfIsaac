a = ""
a += "RULE(" + raw_input("NAME:") + ", "
#a += '"' + '\\x' + '\\x'.join(raw_input("ORIGINAL:").split(' ')) + '", '
#a += '"' + '\\x' + '\\x'.join(raw_input("CHANGE TO:").split(' ')) + '");'
a += 'CODE(' + '0x' + ', 0x'.join(raw_input("ORIGINAL:").split(' ')) + '), '
a += 'CODE(' + '0x' + ', 0x'.join(raw_input("CHANGE TO:").split(' ')) + '));'
print ''
print a
