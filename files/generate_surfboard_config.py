import random,os,json
import configparser
import ipaddress
import string
import sys

def ip2name(ip):
    return ip

def ips():
    with open("../result.csv","r") as file:
        ips = file.readlines()
    for line in ips:
        line = line.strip()
        if not line or line == 'IP:PORT, LOSS, DELAY':
            continue
        ip,loss,delay = line.split(',')
        if delay == '1000 ms' or loss != '0.00%':
            continue
        yield ip
def get_wireguard_config(filename):
    with open(filename,"r") as file:
        configlines = file.readlines()
    # modify it so python can parse it
    configstr = ''
    haveAddress = False
    haveAllowedIPs = False
    for line in configlines:
        if line.startswith('Address'):
            if haveAddress:
                continue
            haveAddress = True
        if line.startswith('AllowedIPs'):
            if haveAllowedIPs:
                continue
            haveAllowedIPs = True
        configstr += line
    print(configstr)
    config = configparser.ConfigParser()
    config.read_string(configstr)
    config.sections()
    return config


def main():
    filename= sys.argv[1]
    config = get_wireguard_config(filename)
    assert config['Peer']['Endpoint'] == 'engage.cloudflareclient.com:2408', "not a warp config"
    assert config['Interface']['Address'].endswith('/32')
    wg_common_config = {
        "private-key": config['Interface']['PrivateKey'],
        "self-ip": config['Interface']['Address'].split('/')[0],
        "dns-server": config['Interface']['DNS'],
        "mtu": config['Interface']['MTU'],
        "peer": f"(public-key = {config['Peer']['PublicKey']}, allowed-ips = {config['Peer']['AllowedIPs']}, endpoint = DUMMY)"
    }
    with open("./template.surfboard.ini", "r") as file:
        template = file.read()
    proxies = []
    i=1
    for item in ips():
        wg_config = wg_common_config.copy()
        wg_config["peer"] = wg_config["peer"].replace("DUMMY", item)
        wg_config["name"] = f"warp {i} ({ip2name(item)})"
        proxies.append(wg_config)
        i+=1
    
    proxies_text = ""
    configs_text = ""
    names_text = ""
    for item in proxies:
        proxies_text += f"{item['name']} = wireguard, section-name={item['name']}\n"
        configs_text += f'''
[WireGuard {item['name']}]
private-key = {item['private-key']}
self-ip = {item['self-ip']}
dns-server = {item['dns-server']}
mtu = {item['mtu']}
peer = {item['peer']}
'''
        names_text += f"{item['name']},"
    names_text = names_text[:-1]
    template = template.replace("{{proxies}}", proxies_text).replace("{{configs}}", configs_text).replace("{{names}}", names_text)
    print(template)
if __name__ == '__main__':
    main()