# AIDE-SERVER :muscle::muscle::muscle:
	
## TODO:
### Client installation script:
#### expect:
  - [ ] check whether */etc/sudoers* has doubled lines when invoked too many times
  - [ ] intime progress displaying
  - [ ] more specific errors (wrong password)
#### bash:
  - [ ] pretty processing (requires intime informing):heart_eyes_cat:
  - [ ] robustness (different error code)
### Backup and Recovery:
#### backup.sh:
- [x] create tar command basing on client's config
- [x] script can be invoked anytime with option -i and then creates backup from scratch (especially when client's config is reconfigured) 
- [x] adding and removing files from archive according to changes detected by AIDE (optinon -a and -r) NOT EFFICIENT WITH TAR
	- [ ] think out how not to initialize dump always when changes are detected
- [ ] think out and introduce better way of archive management (AMANDA?) 
- [x] when file change detected, send old version (*filename.old.unixtime*) to recovery directory and update backup (option -c) 
- [x] improve AIDE log file by including differences between each file versions (problem: check dates of each file)
- robustness:
	- [ ] not enough space for new backup file

### Documentation update:
- update source code
- add script names and specification
- add backup and recovery chapter
- change font to Times New Roman for regular text
- add chapter dedicated to AIDE
- new introduction
- update limitations
