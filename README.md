# F5 / SSLO Custom URL Category Update Script #

- **Description**: provides options to add URLs, delete URLs, and list the URLs in an existing custom URL category
- **Version**: 1.0
- **Requires**: bash, curl, jq
- **To-do**: add BIGIP and LOGIN variables as command input
- **Syntax**:

      To Add URLs:
      Command:    script.sh add <category> <URL> <[exact-match|glob-match]>
      Examples:   script.sh add MY_CATEGORY https://www.example.com/ exact-match
                  script.sh add MY_CATEGORY https://*.foo.com/ glob-match


      To List URLs:
      Command:    script.sh list <category>
      Example:    script.sh list MY_CATEGORY


      To Delete URLs:
      Command:    script.sh del <category> <URL> <[exact-match|glob-match]>
      Examples:   script.sh del MY_CATEGORY https://www.example.com/ exact-match
                  script.sh del MY_CATEGORY https://*.foo.com/ glob-match

