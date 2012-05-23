#!/usr/bin/python
# -*- coding: utf-8 -*-

# Bundeled for the vim-evince-synctex plugin by Phillip Berndt
# See
#  http://jlebl.wordpress.com/2011/01/13/vim-evince-and-forward-and-backward-latex-synctex-search/
# for updated versions / gnome3 support
#
# I changed the script such that it exists if Evince exits. I tagged my changed with XXX.


# This file was part of the Gedit Synctex plugin.
# Slightly modified by _vicious_ ...
#
# Copyright (C) 2010 Jose Aliste <jose.aliste@gmail.com>
#
# This program is free software; you can redistribute it and/or modify it under
# the terms of the GNU General Public Licence as published by the Free Software
# Foundation; either version 2 of the Licence, or (at your option) any later
# version.
#
# This program is distributed in the hope that it will be useful, but WITHOUT
# ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
# FOR A PARTICULAR PURPOSE.  See the GNU General Public Licence for more
# details.
#
# You should have received a copy of the GNU General Public Licence along with
# this program; if not, write to the Free Software Foundation, Inc., 51 Franklin
# Street, Fifth Floor, Boston, MA  02110-1301, USA

import dbus, subprocess, time

RUNNING, CLOSED = range(2)

EV_DAEMON_PATH = "/org/gnome/evince/Daemon"
EV_DAEMON_NAME = "org.gnome.evince.Daemon"
EV_DAEMON_IFACE = "org.gnome.evince.Daemon"

EVINCE_PATH = "/org/gnome/evince/Evince"
EVINCE_IFACE = "org.gnome.evince.Application"

EV_WINDOW_IFACE = "org.gnome.evince.Window"



class EvinceWindowProxy:
    """A DBUS proxy for an Evince Window."""
    daemon = None
    bus = None

    def __init__(self, uri, spawn = False, logger = None):
        self._log = logger
        self.uri = uri
        self.spawn = spawn
        self.status = CLOSED
        self.source_handler = None
        self.close_handler = None
        self.dbus_name = ''
        self._handler = None
        try:
            if EvinceWindowProxy.bus is None:
                EvinceWindowProxy.bus = dbus.SessionBus()

            if EvinceWindowProxy.daemon is None:
                EvinceWindowProxy.daemon = EvinceWindowProxy.bus.get_object(EV_DAEMON_NAME,
                                                EV_DAEMON_PATH,
                                                follow_name_owner_changes=True)
            self._get_dbus_name(False)

        except dbus.DBusException:
            if self._log:
                self._log.debug("Could not connect to the Evince Daemon")

    def _get_dbus_name(self, spawn):
        EvinceWindowProxy.daemon.FindDocument(self.uri,spawn,
                     reply_handler=self.handle_find_document_reply,
                     error_handler=self.handle_find_document_error,
                     dbus_interface = EV_DAEMON_IFACE)

    def handle_find_document_error(self, error):
        if self._log:
            self._log.debug("FindDocument DBus call has failed")

    def handle_find_document_reply(self, evince_name):
        if self._handler is not None:
            handler = self._handler
        else:
            handler = self.handle_get_window_list_reply
        if evince_name != '':
            self.dbus_name = evince_name
            self.status = RUNNING
            self.evince = EvinceWindowProxy.bus.get_object(self.dbus_name, EVINCE_PATH)
            self.evince.GetWindowList(dbus_interface = EVINCE_IFACE,
                          reply_handler = handler,
                          error_handler = self.handle_get_window_list_error)

    def handle_get_window_list_error (self, e):
        if self._log:
            self._log.debug("GetWindowList DBus call has failed")

    def handle_get_window_list_reply (self, window_list):
        if len(window_list) > 0:
            window_obj = EvinceWindowProxy.bus.get_object(self.dbus_name, window_list[0])
            self.window = dbus.Interface(window_obj,EV_WINDOW_IFACE)
            self.window.connect_to_signal("Closed", self.on_window_close)
            self.window.connect_to_signal("SyncSource", self.on_sync_source)
        else:
            #That should never happen. 
            if self._log:
                self._log.debug("GetWindowList returned empty list")


    def set_source_handler (self, source_handler):
        self.source_handler = source_handler

    def set_close_handler (self, close_handler):
        self.close_handler = close_handler

    def on_window_close(self):
        self.window = None
        self.status = CLOSED
        if self.close_handler:
            self.close_handler()

    def on_sync_source(self, input_file, source_link, other):
        if self.source_handler is not None:
            self.source_handler(input_file, source_link)

    def SyncView(self, input_file, data):
        if self.status == CLOSED:
            if self.spawn:
                self._tmp_syncview = [input_file, data];
                self._handler = self._syncview_handler
                self._get_dbus_name(True)
        else:
            self.window.SyncView(input_file, data, 0, dbus_interface = "org.gnome.evince.Window")

    def _syncview_handler(self, window_list):
        self.handle_get_window_list_reply(window_list)

        if self.status == CLOSED: 
            return False
        self.window.SyncView(self._tmp_syncview[0],self._tmp_syncview[1], dbus_interface="org.gnome.evince.Window")
        del self._tmp_syncview
        self._handler = None
        return True

## This file can be used as a script to support forward search and backward search in vim.
## It should be easy to adapt to other editors. 
##  evince_dbus  pdf_file  line_source input_file
if __name__ == '__main__':
    import dbus.mainloop.glib, gobject, glib, sys, os

    def print_usage():
        print '''
The usage (to make evince sync ... will exit when sync done) is evince_vim_dbus EVINCE output_file line_number input_file from the directory of output_file.
'''
        print '''
The usage (to make gvim sync in response to evince clicks, keeps running till killed) is evince_vim_dbus GVIM gvim_server_name output_file input_file from the directory of output_file.
'''
        sys.exit(1)

    if len(sys.argv)!=5:
        print_usage()

    if sys.argv[1] == 'EVINCE':
        try:
            line_number = int(sys.argv[3])
        except ValueError:
            print_usage()
  
        output_file = sys.argv[2]
        input_file  = sys.argv[4]
        path_output  = os.path.abspath(output_file)
        path_input   = os.path.abspath(input_file)
  
        if not os.path.isfile(path_output):
            print_usage()
  
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        a = EvinceWindowProxy('file://' + path_output, True )
    
        def sync_view(ev_window, path_input, line_number):
            ev_window.SyncView (path_input, (line_number, 1))
            exit(0)

        glib.timeout_add(400, sync_view, a, path_input, line_number)
        loop = gobject.MainLoop()
        loop.run() 

    elif sys.argv[1] == 'GVIM':
        gvim_server_name = sys.argv[2]
        output_file = sys.argv[3]
        input_file  = sys.argv[4]
        path_output  = os.path.abspath(output_file)
        path_input   = os.path.abspath(input_file)
  
        if not os.path.isfile(path_input):
            print_usage()

        def source_view_handler(input_file, source_link):
            if input_file[:7] == "file://":
                input_file = input_file[7:]
            print 'gvim --servername "' + gvim_server_name + '" --remote +' + str(source_link[0]) + ' ' + input_file
            os.system('gvim --servername "' + gvim_server_name + '" --remote +' + str(source_link[0]) + ' ' + input_file)
  
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        a = EvinceWindowProxy('file://' + path_output, True )
    
        a.set_source_handler(source_view_handler)
        loop = gobject.MainLoop()
        a.set_close_handler(lambda *x: loop.quit())
        loop.run() 
    else:
        print_usage()


# ex:ts=4:et:
