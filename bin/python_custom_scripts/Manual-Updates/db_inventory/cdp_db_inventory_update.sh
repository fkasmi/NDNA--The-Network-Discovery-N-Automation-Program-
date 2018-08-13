#!/bin/sh

## 
## ------------------------------------------------------------------
##     NDNA: The Network Discovery N Automation Program
##     Copyright (C) 2017  Brett M Spunt, CCIE No. 12745 (US Copyright No. TXu 2-053-026)
## 
##     This file is part of NDNA.
##
##     NDNA is free software: you can redistribute it and/or modify
##     it under the terms of the GNU General Public License as published by
##     the Free Software Foundation, either version 3 of the License, or
##     (at your option) any later version.
## 
##     NDNA is distributed in the hope that it will be useful,
##     but WITHOUT ANY WARRANTY; without even the implied warranty of
##     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##     GNU General Public License for more details.
##
##     This program comes with ABSOLUTELY NO WARRANTY.
##     This is free software, and you are welcome to redistribute it
##
##     You should have received a copy of the GNU General Public License
##     along with NDNA.  If not, see <https://www.gnu.org/licenses/>.
## ------------------------------------------------------------------
## 

echo "#################################################################"
read -p "Enter Data_Center String Here e.g. New-York-DC: " DataCenter
echo "#################################################################"
echo ""
echo ""
echo "###########################################################################################"
echo "You will be prompted to enter the DataCenter Name Once more when the Python Script Runs...."
echo "###########################################################################################"
echo ""
echo ""

DataCenterdir=/usr/DataCenters/$DataCenter
 
if [ -d "$DataCenterdir" ];
then
   echo "Data_Center Exists...."
else
   echo "Data_Center does not exist...Program exiting. Goodbye..."
   echo ""
   exit 1
fi
## truncate the CDP DB
python /usr/DCDP/bin/python_custom_scripts/Manual-Updates/db_inventory/CDP/CDP-Truncate-DB-Manual.py /usr/DCDP/bin/python_custom_scripts/Manual-Updates/db_inventory/CDP/db_cdp_connection.txt 

## REPOPULATE THE CDP inventory from live network discovery
python /usr/DCDP/bin/python_custom_scripts/Manual-Updates/db_inventory/CDP/CDP_inventory.py /usr/DCDP/bin/python_custom_scripts/Manual-Updates/db_inventory/CDP/db_cdp_connection.txt

# kill all python thread processes to cleanup as a safety-net
ps -fLu root | grep python | awk {'print $2'} | xargs kill -9

### create new backup SQL DB to DataCenter, then regenerate new CDP xml file.....
echo "###########################################################################################"
echo " Generating new CDP xml file and backing up the CDP SQL DB to $DataCenter."
echo "###########################################################################################"
 user="root"
 password="dcdp"
 host="localhost"
 db_name="CDP"
 db_table="CDP_Inventory"
# Other options
 backup_path="/usr/DataCenters/$DataCenter/DCDP/CDP-Inventory"
 date=$(date +"%d-%b-%Y")
# Set default file permissions
 umask 177
# Dump database into SQL file
 mysqldump --user=$user --password=$password --host=$host $db_name $db_table > $backup_path/$db_table-$date.sql
# Dump database into xml file
 mysqldump --user=$user --password=$password --xml --host=$host $db_name $db_table > $backup_path/$db_table.xml