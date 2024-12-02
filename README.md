Original App Design Project - README Template
===

# BarterUp

## Table of Contents

1. [Overview](#Overview)
2. [Product Spec](#Product-Spec)
3. [Wireframes](#Wireframes)
4. [Schema](#Schema)

## Overview

### Description

BarterUp is a skill-trading app that connects users locally or virtually to exchange micro-skills. Whether you're offering guitar lessons or need help with Excel formulas, BarterUp simplifies skill-sharing by fostering collaboration and removing the need for monetary transactions. Using geolocation and matchmaking, the app helps users find compatible skill-trading partners with ease.

### App Evaluation

[Evaluation of your app across the following attributes]
- **Category:** Productivity / Social Networking
- **Mobile:** Mobile-first design for local and virtual skill exchanges.
- **Story:** Encourages skill-swapping instead of monetary transactions, creating a collaborative and community-driven space.
- **Market:** Targets students, freelancers, and hobbyists interested in learning and teaching new skills.
- **Habit:** Designed for occasional, purposeful use to arrange skill trades.
- **Scope:** Core features include skill-sharing, matchmaking, and messaging, with optional enhancements for scheduling and group learning.

## Product Spec

### 1. User Stories (Required and Optional)

**Required Must-have Stories**

* Users can create a profile to list skills they can teach and skills they want to learn.
* Users can browse other profiles to view available skills.
* Users can search for nearby users with specific skills using geolocation.
* Users can message matched users to arrange a skill trade.
* Users can view a history of their skill trades.

**Optional Nice-to-have Stories**

* Users can rate and review their skill-trading partners.
* Users can set availability for skill trades (e.g., specific times or dates).
* Users can join local "Skill Circles" for group learning.
* Integration with a calendar API for scheduling trades.

### 2. Screen Archetypes

- [ ] **Onboarding Screen**
* Allows users to sign up and set up their profiles.
- [ ] **Home Screen**
* Displays a feed of nearby users or skill matches.
- [ ] **Profile Screen**
* Users can list their skills, short bio, and other details
- [ ] **Search Screen**
* Enables users to search for specific skills or browse by category
- [ ] **Messaging Screen**
* Chat functionality for arranging skill trades
- [ ] **Favorites screen**
* Displays a list of favorite skills you've favorited


### 3. Navigation

**Tab Navigation** (Tab to Screen)

- [ ] Home
- [ ] Search
- [ ] Profile
- [ ] Messages
- [ ] Favorites

**Flow Navigation** (Screen to Screen)

- [ ] **Onboarding Screen**
  * Leads to [**Home Screen**]
- [ ] **Home Screen**
  * Leads to [**Profile Screen**] 
- [ ] **Profile Details of another user**
  * Leads to [**Next Screen**]
- [ ] **Messaging Screen**
  * Leads to [**Chat Details**]
- [ ] **Favorites Screen**
  * Leads to [**Favorite skills**]


## Wireframes

![Screenshot 2024-12-02 at 1.18.19 PM](https://hackmd.io/_uploads/B1Vz5_jmkl.png)



## Schema 


### Models

**User** 
| Property  | Type   | Description                                 |
| --------  | ------ | ------------------------------------------- |
|    id     | String |   Unique ID for the habit                   |
|   name    | String |    Name of the habit                        |
| bio       | String |    Short bio describing the user            |
|skillsOffer| Array  |     List of skills the user can teach       |
|skillsLearn| Array  |List of skills the user wants to learn       |


**Trade**
| Property      | Type   | Description                                 |
| ------------- | ------ | ------------------------------------------- |
|    id         | String |   Unique identifier for each skill trade    |
|   user1       | Pointer|   Reference to the first user               |
| user2         | Pointer|Reference to the second user                 |
|skillsExchanged| Array  |  Skills exchanged in the trade              |
| date          |DateTime| Date and time of the trade                  |

### Networking

- [List of network requests by screen]

* Login and Sign-up Screen
[POST] /auth/login - Authenticates user credentials.
[POST] /auth/signup - Creates a new user account.

* Home Screen
[GET] /users - Fetch a list of nearby users and their skills.

* Favorites Screen
[GET] /users/favorites - Fetches favorited profiles for the user.


* Search Screen
[GET] /users?skills=skillName - Search for users offering a specific skill.

* Profile Screen
[POST] /users - Create or update a user profile.

* Messaging Screen
[GET] /messages?userId={id} - Fetch chat history with a specific user.
[POST] /messages - Send a message to a user.

* History Screen
[GET] /trades?userId={id} - Fetch the user’s past skill trades.
