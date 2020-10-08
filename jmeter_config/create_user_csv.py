import sys 
lower = int(sys.argv[1])
upper = int(sys.argv[2])
username = "user"

with open("users.csv", "w") as file:
    file.write("username\n")
    for i in range(lower, upper, 1):
        line = "user{}\n".format(i)
        file.write(line)

print("finished creating {} users (from {} to {})".format(upper-lower, lower, upper))
