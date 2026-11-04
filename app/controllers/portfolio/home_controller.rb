class Portfolio::HomeController < ApplicationController
  def home

    @projects = [
      {
        title: "Sudoku Solver",
        image: "sudoku.png",
        description: "A web application that allows users to input a Sudoku puzzle and provides a solution using a human-like approach modeled in Ruby.",
        github_link: "https://github.com/marshallhelenm/el-dev-portfolio",
        live_link: "/sudoku"
      },
      {
        title: "Memetic",
        image: "question.png",
        description: "A web-based multiplayer game inspired by the classic “Guess Who?”, but with memes instead of cartoon faces! Built with Vite + React, react-use-websocket for real-time communication, and Material UI for sleek styling.",
        github_link: "https://github.com/marshallhelenm/memetic",
        live_link: "https://memetic-app-d0ed892a999c.herokuapp.com/"
      }
    ]

    @android_apps = [
      {
        title: "Habit Piggy",
        image: "android/habit-piggy.png",
        image_class: "app-screenshot",
        description: "A habit tracker where keeping your streaks fills a piggy bank. Every check-in earns coins toward a savings goal, and the longer the streak, the more it pays."
      },
      {
        title: "Knimble",
        image: "android/knimble.png",
        image_class: "app-screenshot",
        description: "A timer for crafters. Start it when you sit down to knit, crochet or draw, and when it goes off it hands you a random gentle stretch to do before you carry on."
      },
      {
        title: "Randominder",
        image: "android/randominder.png",
        image_class: "app-screenshot",
        description: "Reminders that ping at random times within a window you choose, each with a random message and sound, so they don't fade into the background."
      },
      {
        title: "PhotoBracket",
        image: "android/photobracket.png",
        image_class: "app-screenshot",
        description: "A photo culling app that shows two photos at a time. Keep one, both or neither, bracket-style, until only the keepers are left."
      }
    ]
  end

  def about
  end

  def contact
  end
end