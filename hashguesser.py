#!/usr/bin/python
import sys
import itertools
import hashlib
import hmac

fields = []
fields = sys.argv[1].split("|")
separators = [",",".","-",";",":","_","|"," ","\t",""]
md5 = hashlib.md5()

def init():
    if (len(fields) <= 0):
        usage()
        exit(1)

    print("Hash Guesser running with the following attributes:")
    print("Fields: %s" % fields)
    print("Separators: %s" % separators)

def calculate_md5(permutation, separator):
    string_to_hash = separator.join(permutation)
    md5.update(string_to_hash)
    hash_value = md5.hexdigest()
    print("[md5] string: %s => %s" % (string_to_hash, hash_value))
                

def calculate_hmac(permutation, separator):
    key = permutation[0]
    string_to_hash = separator.join(permutation[1:])
    hmac_obj = hmac.new(key, string_to_hash)
    hash_value = hmac_obj.hexdigest() 
    print("[hmac] key: %s, string: %s  => %s" % (key, string_to_hash, hash_value))

def main():
    #every length
    print(fields)
    for length in range(1,len(fields)+1):
        for permutation in itertools.permutations(fields, length):
            for separator in separators:
                calculate_md5(permutation, separator)
                calculate_hmac(permutation, separator)
    exit(0)

init()
main()
