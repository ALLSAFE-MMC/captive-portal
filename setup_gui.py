import os
import tkinter as tk
from tkinter import messagebox

def install():
    os.system('sh /usr/local/captive-portal/setup.sh')
    messagebox.showinfo("Kurulum", "Kurulum tamamlandı!")

root = tk.Tk()
root.title("Captive Portal Kurulum")

label = tk.Label(root, text="Captive Portal Kurulumuna Hoş Geldiniz")
label.pack(pady=10)

install_button = tk.Button(root, text="Kurulumu Başlat", command=install)
install_button.pack(pady=10)

root.mainloop()
