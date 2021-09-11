FROM python:3
ADD lichess-bot.py /
#RUN python3 -m venv venv #if this fails you probably need to add Python3 to your PATH
#RUN  virtualenv venv -p python3 #if this fails you probably need to add Python3 to your PATH
ENV VIRTUAL_ENV=/opt/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="./:$VIRTUAL_ENV/bin:$PATH"
#RUN source ./venv/bin/activate
COPY requirements.txt .
RUN pip install -r requirements.txt

COPY lichess-bot.py .
COPY engine_wrapper.py .
COPY model.py .
COPY lichess.py .
COPY logging_pool.py .
COPY config.py .
COPY conversation.py .
COPY ColorLogger.py .
COPY config.py .
COPY config.yml .

RUN mkdir ./engines/
ADD engines/ctengine ./engines/
COPY engines/README.md ./engines/
CMD [ "python",  "lichess-bot.py" ]
