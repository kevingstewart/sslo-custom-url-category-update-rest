# F5 / SSLO Custom URL Category Update Script #

- **Description**: provides options to add URLs, delete URLs, and list the URLs in an existing custom URL category
- **Version**: 2.1
- **Requires**: bash, curl, jq
- **Syntax**:

      -h     = show this help
      -l     = list entries in the URL category
      -a     = add an entry to the URL category
      -d     = delete an entry from the URL category
      -t     = replace the contents of URL category (overwrite)
      -f     = used with -a and -d to specify a file to read from
      -b     = the IP address of the BIG-IP
      -u     = username for the BIG-IP (script will prompt for password)

- **Examples**:

      Show help:            ./urlupdater.sh -h
      List URLs:            ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -l
      Add single entry:     ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -a https://www.foo.com/
      Add file entries:     ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -a file -f testfile.txt
      Delete single entry:  ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -d https://www.foo.com/
      Delete file entries:  ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -d file -f testfile.txt
      Replace all entries:  ./urlupdater.sh -b 172.16.1.84 -u admin -c test-category -t file -f testfile.txt

- **URL Format**:
Supplied URLs must be in the following format:

      https://URL/

      Example: https://www.foo.com/

