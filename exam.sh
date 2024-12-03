#!/bin/bash

echo "Content-type: text/html"
echo ""  # Blank line required between headers and body

# File to store user credentials
user_file="/var/www/html/users1.txt"
# File containing the list of cities (Name, Latitude, Longitude)
cities_file="/var/www/html/cities.txt"
# File containing the list of city temperatures
temperature_file="/var/www/html/temperature_data.json"

# Function to hash passwords
hash_password() {
  echo -n "$1" | openssl dgst -sha256 | awk '{print $2}'
}

# Function to validate user credentials
validate_user() {
  local username="$1"
  local hashed_password="$2"
  while IFS=: read -r file_username file_password; do
    if [[ "$file_username" == "$username" ]]; then
      if [[ "$file_password" == "$hashed_password" ]]; then
        return 0  # Valid credentials
      fi
    fi
  done < "$user_file"
  return 1  # Invalid credentials
}

# Function to decode URL-encoded strings
urldecode() {
  local encoded="$1"
  printf '%b' "${encoded//%/\\x}"
}

# Extract parameters from query string
parse_query_string() {
  local query="$1"
  local key_value
  IFS='&' read -ra key_value <<< "$query"
  for pair in "${key_value[@]}"; do
    local key=$(echo "$pair" | cut -d'=' -f1)
    local value=$(echo "$pair" | cut -d'=' -f2)
    eval "$key=\"$(urldecode "$value")\""
  done
}

# Check if the query string exists and parse it
if [[ -n "$QUERY_STRING" ]]; then
  parse_query_string "$QUERY_STRING"
fi

# Handle logout (removes username from URL query string)
if [[ "$QUERY_STRING" == *"logout=true"* ]]; then
  echo ""  # Blank line required between headers and body
  echo "<html><body><center><p>You have been logged out. <a href='eksamen1.sh'>Login again</a>.</p></center></body></html>"
  exit 0
fi

# Handle login
if [[ -n "$username" && -n "$password" && "$action" == "login" ]]; then
  hashed_password=$(hash_password "$password")
  if validate_user "$username" "$hashed_password"; then
    # Redirect to the game page with the username in the query string
    echo ""  # End of headers
    echo "<html><body><center><p>Login successful! <a href='eksamen1.sh?play=true&username=$username'>Start the game</a>.</p></center></body></html>"
    exit 0
  else
    echo ""  # End of headers
    echo "<html><body><center><p>Invalid credentials. <a href='eksamen1.sh'>Try again</a>.</p></center></body></html>"
    exit 0
  fi
fi

# Handle sign-up
if [[ -n "$username" && -n "$password" && "$action" == "signup" ]]; then
  while IFS=: read -r file_username _; do
    if [[ "$file_username" == "$username" ]]; then
      echo ""  # End of headers
      echo "<html><body><center><p>Username already exists. <a href='eksamen1.sh'>Try again</a>.</p></center></body></html>"
      exit 0
    fi
  done < "$user_file"
  hashed_password=$(hash_password "$password")
  echo "$username:$hashed_password" >> "$user_file"
  echo ""  # End of headers
  echo "<html><body><center><p>Signup successful! <a href='eksamen1.sh'>Login now</a>.</p></center></body></html>"
  exit 0
fi

# Check if user is logged in (username is in the query string) and wants to play the game
if [[ -n "$username" && "$QUERY_STRING" == *"play=true"* ]]; then
  echo ""
  echo "<html><body style='background-color: lightblue; margin-top: 150px;'>"
  echo "<center>"
  echo "<h1>Guess the Temperature Game!</h1>"
  echo "<p>Welcome, $username!</p>"
  
  # Fetch a random city from the cities file
  random_city=$(shuf -n 1 "$cities_file")
  city_name=$(echo "$random_city" | cut -d',' -f1)
  latitude=$(echo "$random_city" | cut -d',' -f2)
  longitude=$(echo "$random_city" | cut -d',' -f3)

  # The line uses jq to search for a city in the $temperature_file JSON file.
  # It passes the city name from Bash to jq, which filters the JSON data to find the correct city.
  # It extracts the temperature for that city and assigns it to the city_temp variable.
  city_temp=$(jq -r --arg city "$city_name" '.[] | select(.city == $city) | .temperature' "$temperature_file")

  # Form for the user to make a guess
  echo "<p>Guess the current temperature in $city_name:</p>"
  echo "<form method='get' action='eksamen1.sh'>"
  echo "<input type='text' name='user_guess' placeholder='Enter your guess in Celsius' />"
  echo "<input type='hidden' name='city_name' value='$city_name' />"
  echo "<input type='hidden' name='latitude' value='$latitude' />"
  echo "<input type='hidden' name='longitude' value='$longitude' />"
  echo "<input type='hidden' name='username' value='$username' />"  # Make sure username is passed here
  echo "<input type='submit' value='Submit Guess' />"
  echo "</form>"

  echo "<p><a href='eksamen1.sh?logout=true&username=$username'>Logout</a></p>"
  echo "</center>"
  echo "</body></html>"
  exit 0
fi

# The if statement checks if five variables (user_guess, city_name, latitude, longitude, and username) are non-empty.
# If all these variables have values (i.e., none of them are empty), the script proceeds to execute the code inside the if block.
# This ensures that the game only continues when all the necessary inputs (such as the user's guess and the city information) are available, preventing errors or incomplete game logic.

if [[ -n "$user_guess" && -n "$city_name" && -n "$latitude" && -n "$longitude" && -n "$username" ]]; then
  # jq is used to parse the JSON file and extract the temperature for a city.
  # --arg city "$city_name" passes the city name from the Bash script into jq.
  # The .[] | select(.city == $city) | .temperature expression filters the array for the city and returns the associated temperature.
  # The result is stored in the actual_temp variable for later use in the script.
  actual_temp=$(jq -r --arg city "$city_name" '.[] | select(.city == $city) | .temperature' "$temperature_file")
  
  # echo "$user_guess - $actual_temp": Prints the subtraction operation.
  # bc: Calculates the result of the subtraction.
  # tr -d -: Removes the minus sign if the result is negative, ensuring the result is always positive (absolute difference).
  # The final value of diff will be the absolute difference between the user's guess and the actual temperature.
  diff=$(echo "$user_guess - $actual_temp" | bc | tr -d -)

  echo ""
  echo "<html><body style='background-color: lightblue; margin-top: 150px;'>"
  echo "<center>"
  echo "<h1>Guess the Temperature Game!</h1>"
  echo "<p>Your guess: $user_guess&deg;C</p>"
# Making a function that firstly checks if the player guesses the exact right number, using the "DIFF" as the difference between
    # the guess and the actual temp, and "bc -l" because we needed basic calculator with integer calculations because the difference
    # often will be with decimal points
    if (( $(echo "$diff == 0" | bc -l) )); then
        # then printing out this message
        echo "Wow! You got it on the dot! How did you manage to do that??"
    # checking this condition if the last condition is not met, so if the guess is not exactly right, it checks if the differnce is
    # less than 3 degrees with the same logic as the last one
    elif (( $(echo "$diff < 3" | bc -l) )); then
        # if the difference is less than 3 degrees, we print out this message
        echo "Congratulations! The actual temperature in ${city_name} is ${actual_temp}&deg;C. You won!"
    # we made this condition that will print out a message if none of the conditions above are met, i.e. if the guessed temperature
    # is not equal to or less than 3 degrees away from the actual temperature (the user looses)
    else
        # then we print out this message 
        echo "Sorry, the actual temperature in ${city_name} is ${actual_temp}&deg;C. Better luck next time!"        
    fi

  # Play again with the username passed correctly in the URL
  echo "<p>Play again? <a href='eksamen1.sh?play=true&username=$username'>Yes</a> | <a href='eksamen1.sh?logout=true&username=$username'>No, Logout</a></p>"
  echo "</center>"
  echo "</body></html>"
  exit 0
fi

# Display the login/signup form if no action is taken
echo ""
echo "<html>"
echo "<body style='background-color: lightblue; margin-top: 150px;'>"
echo "<center>"
echo "<h1>Welcome to the Guess the Temperature Game!</h1>"
echo "<form method='get' action='eksamen1.sh'>"
echo "<input type='text' name='username' placeholder='Username' required /><br><br>"
echo "<input type='password' name='password' placeholder='Password' required /><br><br>"
echo "<button type='submit' name='action' value='login'>Log In</button>"
echo "<button type='submit' name='action' value='signup'>Sign Up</button>"
echo "</form>"
echo "</center>"
echo "</body>"
echo "</html>"
