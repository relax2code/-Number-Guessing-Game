#! /bin/bash
PSQL="psql -X --username=freecodecamp --dbname=number_guess --tuples-only -c"

MAIN_MENU() {
  echo "Enter your username:"
  read USERNAME

  if [[ -z $USERNAME ]]; then
    echo -e "Please provide your name."
  else
    PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE name='$USERNAME';")
    if [[ -z $PLAYER_ID ]]; then
      PLAYER_ID=$($PSQL "INSERT INTO players (name) VALUES ('$USERNAME') RETURNING player_id;")
      echo "Welcome, $USERNAME! It looks like this is your first time here."
    else
      PLAYED=$($PSQL "SELECT COUNT(*) FROM games WHERE player_id=$PLAYER_ID;")
      BEST=$($PSQL "SELECT tries FROM games WHERE player_id=$PLAYER_ID AND tries > 0 ORDER BY tries ASC LIMIT 1;")
      PLAYED_FORMATTED=$(echo $PLAYED | sed 's/ |/"/')
      BEST_FORMATTED=$(echo $BEST | sed 's/ |/"/')
      echo "Welcome back, $USERNAME! You have played $PLAYED_FORMATTED games, and your best game took $BEST_FORMATTED guesses."
    fi
    GAMEPLAY $PLAYER_ID
  fi
}

GAMEPLAY() {
  PLAYER_ID=$1
  # echo "PLAYER_ID: $PLAYER_ID"
  SECRET_NUMBER=$(($RANDOM % 1000 + 1))
  NUMBER_OF_GUESSES=1

  GAME_ID=$($PSQL "INSERT INTO games (player_id) VALUES ($PLAYER_ID) RETURNING game_id;" | head -n 1)
  GAME_ID=$(echo $GAME_ID | sed 's/ |/"/')
  # echo "GAME_ID: $GAME_ID"

  echo "Guess the secret number between 1 and 1000:"
  read GUESS_NUMBER

  while [[ $GUESS_NUMBER -ne $SECRET_NUMBER ]]; do

    # echo "The right number $SECRET_NUMBER"
    # echo "Guess number $GUESS_NUMBER"
    if [[ ! $GUESS_NUMBER =~ ^[0-9]+$ ]]; then
      echo "That is not an integer, guess again:"
      read GUESS_NUMBER
    elif [[ $GUESS_NUMBER -lt $SECRET_NUMBER ]]; then
      echo "It's higher than that, guess again:"
      NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
      read GUESS_NUMBER
    elif [[ $GUESS_NUMBER -gt $SECRET_NUMBER ]]; then
      echo "It's lower than that, guess again:"
      NUMBER_OF_GUESSES=$((NUMBER_OF_GUESSES + 1))
      read GUESS_NUMBER
    fi
  done

  UPDATE_GAME_RESULT=$($PSQL "UPDATE games SET tries=$NUMBER_OF_GUESSES WHERE game_id=$GAME_ID;")

  echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
}

MAIN_MENU

