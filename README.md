
# IW6: Call of duty: Ghost Mapvote
Developed by [@DoktorSAS](https://twitter.com/DoktorSAS)

<div id="header" align="center">
  <h1> IW6: Call of duty: Ghost Mapvote</h1>

  [![Build Badge](https://img.shields.io/badge/Developed_by-DoktorSAS-brightgreen?style=for-the-badge&logo=x)](https://twitter.com/DoktorSAS)
  [![License](https://img.shields.io/badge/LICENSE-GPL--3.0-blue?style=for-the-badge&logo=appveyor)](LICENSE)

  ![Preview](https://pbs.twimg.com/media/FgLjl0OWIAAOcLN?format=jpg&name=large)

</div>

### Requirements

- The script can only work on Server's, It will not work in private games.
- Server must be hosted on Plutonium client, the script works only on Plutonium client.

## Installation

### **How to setup the mapvote step by step**

1. **Place the Compiled File:**
   Copy the file into your directory ` %localappdata%\xlabs\data\iw6\data\` or `%gamefolder%\iw6\scripts\` or `%gamefolder%\scripts\`.

3. **Configure Server File:**
   Copy the content of `mapvote.cfg` into your server configuration file (e.g., `server.cfg`, `dedicated_zm.cfg`, `dedicated.cfg`, etc.) that manages the server.

4. **Edit Dvars on your configuration file:**
   - Set the Dvar `mv_maps` to specify the maps shown in the mapvote. For example:
     ```
     set mv_maps "mp_prisonbreak mp_dart mp_lonestar mp_frag mp_snow mp_fahrenheit"
     ```
   - Set the Dvar `mv_enable` to 1 to activate the mapvote on your Zombies server.
   - Set the Dvar `mv_gametypes` to specify the maps shown in the mapvote. For example:
     ```
     set mv_maps "dm war sd sr
     ```

5. **Run the Server:**
   Start the server and enjoy the map voting experience. You're done!
