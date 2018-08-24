# AIDE-SERVER :muscle::muscle::muscle:
	
## TODO:
### client installation script:
#### expect:
  - [ ] check whether */etc/sudoers* has doubled lines
  - [ ] intime informing bash about progress
  - [ ] more specific errors (wrong password)
#### bash:
  - [ ] pretty processing (required intime informing):heart_eyes_cat:
  - [ ] robustness (diffrent error code)
### backup and recovery:
#### backup.sh:
- [x] create tar command basing on client's config
- [ ] script can be invoked anytime with option -i and then creates backup from scratch (especially when client's config is reconfigured) 
- [ ] adding and removing files from backup according to changes detected by AIDE (optinon -a and -r)
- [ ] :fire: when file change detected, send old version (*filename.old.unixtime*) to recovery directory and update backup (option -c) 
- [ ] improve AIDE log file by including differences between file versions
- robustness:
	- [ ] not enough space for new backup file

### documentation update:
- add script names and specification
- update source code
- add backup and recovery chapter
- change font to Times New Roman for regular text
- add chapter ddedicated to AIDE
- new introduction
- update limitation
	- client's hostname has to be unique
