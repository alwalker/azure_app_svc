FROM python:3
WORKDIR /app

RUN pip3 install flask
RUN pip3 install psycopg2

COPY api.py /app

CMD ["python3", "api.py"]
