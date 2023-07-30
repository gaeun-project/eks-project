 FROM amazon/aws-lambda-python:3.8
# Custodian을 설치

RUN /var/lang/bin/python3.8 -m pip install --upgrade pip

# RUN yum install git -y

# RUN git clone https://github.com/gaeun-project/eks-project.git

# RUN pwd

RUN ls -l

# RUN pip install -r ./features/tagging/custodian/requirements.txt

RUN pip install boto3 jinja2 c7n custodian

COPY ./features/tagging/custodian/ /var/task/

RUN chmod +x /var/task/custodian.py
RUN chmod +x /var/task/custodian.json
RUN chmod +x /var/task/custodian.yaml.j2

RUN ls -l /var/task/

CMD ["custodian.lambda_handler"]