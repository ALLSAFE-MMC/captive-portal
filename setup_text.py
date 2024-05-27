import os
import curses

def main(stdscr):
    curses.curs_set(0)  # Hide the cursor
    stdscr.clear()
    stdscr.border(0)
    stdscr.addstr(2, 2, "Welcome to Captive Portal Installer")
    stdscr.addstr(4, 2, "Press 'i' to start the installation.")
    stdscr.addstr(5, 2, "Press 'q' to quit.")
    stdscr.refresh()

    while True:
        key = stdscr.getch()

        if key == ord('q'):
            break
        elif key == ord('i'):
            stdscr.clear()
            stdscr.border(0)
            stdscr.addstr(2, 2, "Installation in progress...")
            stdscr.refresh()
            result = os.system('sh /usr/local/captive-portal/setup.sh')
            stdscr.clear()
            stdscr.border(0)
            if result == 0:
                stdscr.addstr(2, 2, "Installation completed successfully!")
            else:
                stdscr.addstr(2, 2, "Installation failed. Please check error.txt for details.")
            stdscr.addstr(4, 2, "Press any key to exit.")
            stdscr.refresh()
            stdscr.getch()
            break

if __name__ == "__main__":
    curses.wrapper(main)
