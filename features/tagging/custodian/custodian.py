from jinja2 import Environment, FileSystemLoader
import json
import boto3
import c7n
import os
import tempfile



def lambda_handler(event, context):
    # print(event)
    invoking_event = json.loads(event['invokingEvent'])
    configuration_item = invoking_event['configurationItem']
    resource_type = configuration_item['resourceType']
    resource_id = configuration_item['resourceId']
    resource_name = configuration_item.get('tags', {}).get('Name', '-')


    with open('./custodian.json', 'r') as file:
        data = json.load(file)
    if configuration_item['configurationItemStatus'] == 'ResourceDiscovered':
        print(f'{resource_type} 리소스({resource_id})가 생성되었습니다.')
        for key, value in data.items():
            if resource_type==key:
                custodian(value,resource_name,resource_id)
                
            

def custodian(value,resource_name,resource_id):

    value1,value2=tag_value(resource_name)
    #YAML 템플릿 파일이 있는 디렉토리를 설정합니다.
    file_loader = FileSystemLoader('./')
    env = Environment(loader=file_loader)

    # 템플릿 파일 이름을 지정합니다.
    template = env.get_template('custodian.yaml.j2')
    
    # 파라미터 값을 설정합니다.
    params = {'resourcename': value[0], 'resourcetype': value[1],  'resourceid': resource_id, 'project': value1, 'stage': value2}

    # 파라미터를 적용하여 새 YAML 파일을 생성합니다.
    output = template.render(params)

    print(output)
    with tempfile.NamedTemporaryFile(mode='w', suffix='.yaml', delete=False) as f:
        f.write(output)
        temp_path = f.name
    print(temp_path)
    output_dir = "/tmp/custodian-policy"
    os.makedirs(output_dir, exist_ok=True)


    cache_dir = "/tmp/custodian-cache"
    os.makedirs(cache_dir, exist_ok=True)

    cache_file = "/tmp/custodian-cache/cache.json"
    # 실행 권한을 부여합니다.
    os.system(f"chmod 777 {temp_path}")
    # 임시 파일을 사용하여 custodian 명령을 실행합니다.

    # os.system(f"custodian run --output-dir=. {temp_path}")
    os.system(f"custodian run --cache={cache_file} --output-dir={output_dir} {temp_path}")

    # 임시 파일을 제거합니다.
    os.unlink(temp_path)

    # os.system("chmod +x ./custodian_test2.yaml")
    # os.system("custodian run --output-dir=. ./custodian_test2.yaml")


def tag_value(name_tag):
    parts = name_tag.split('-')
    value1=""
    value2=""
    print(parts[0],parts[1])
    if parts[0] == '':
        parts[0] ="none"
    if parts[1] == '':
        parts[1] ="none"
    if len(parts) >= 2:
        value1 = parts[0]
        value2 = parts[1]

    return value1,value2