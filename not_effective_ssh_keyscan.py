import subprocess

def run_command(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE)
    process.wait()
    print(process.returncode)

if __name__ == "__main__":
    with open("servers.txt") as f:
        lines = f.readlines()
        for line in lines:
            line = line.strip()
            line = line.split("@")[1]
            # print(f"ssh-keyscan {line} >> ~/.ssh/known_hosts")
            run_command(f"ssh-keyscan {line} >> ~/.ssh/known_hosts")