python3 -m venv venv #if this fails you probably need to add Python3 to your PATH
virtualenv venv -p python3 #if this fails you probably need to add Python3 to your PATH
source ./venv/bin/activate
python3 -m pip install -r requirements.txt

python lichess-bot.py -u
