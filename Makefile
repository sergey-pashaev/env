install-ansible:
	sudo apt-get install software-properties-common
	sudo apt-add-repository -y ppa:ansible/ansible
	sudo apt-get update
	sudo apt-get install -y ansible git

env:
	ansible-playbook -vvv -K main.yml

py3-by-default:
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 1
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 2
	python --version

py2-by-default:
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python2 2
	sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1
	python --version
