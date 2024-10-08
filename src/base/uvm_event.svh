//
//------------------------------------------------------------------------------
// Copyright 2011 AMD
// Copyright 2007-2018 Cadence Design Systems, Inc.
// Copyright 2014 Cisco Systems, Inc.
// Copyright 2020-2022 Marvell International Ltd.
// Copyright 2007-2011 Mentor Graphics Corporation
// Copyright 2013-2024 NVIDIA Corporation
// Copyright 2011 Synopsys, Inc.
//   All Rights Reserved Worldwide
//
//   Licensed under the Apache License, Version 2.0 (the
//   "License"); you may not use this file except in
//   compliance with the License.  You may obtain a copy of
//   the License at
//
//       http://www.apache.org/licenses/LICENSE-2.0
//
//   Unless required by applicable law or agreed to in
//   writing, software distributed under the License is
//   distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR
//   CONDITIONS OF ANY KIND, either express or implied.  See
//   the License for the specific language governing
//   permissions and limitations under the License.
//------------------------------------------------------------------------------

//----------------------------------------------------------------------
// Git details (see DEVELOPMENT.md):
//
// $File$
// $Rev$
// $Hash$
//
//----------------------------------------------------------------------


//------------------------------------------------------------------------------
//
// CLASS -- NODOCS -- uvm_event_base
//
// The uvm_event_base class is an abstract wrapper class around the SystemVerilog event
// construct.  It provides some additional services such as setting callbacks
// and maintaining the number of waiters.
//
//------------------------------------------------------------------------------

// @uvm-ieee 1800.2-2020 auto 10.1.1.1
virtual class uvm_event_base extends uvm_object;

        `uvm_object_abstract_utils(uvm_event_base)

    protected event      m_event;
    protected int        num_waiters;
    protected bit        on;
    protected time       trigger_time=0;

    // Function -- NODOCS -- new
    //
    // Creates a new event object.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.1
    function new (string name="");
        super.new(name);
    endfunction  

    //---------//
    // waiting //
    //---------//

    // Task -- NODOCS -- wait_on
    //
    // Waits for the event to be activated for the first time.
    //
    // If the event has already been triggered, this task returns immediately.
    // If ~delta~ is set, the caller will be forced to wait a single delta #0
    // before returning. This prevents the caller from returning before
    // previously waiting processes have had a chance to resume.
    //
    // Once an event has been triggered, it will be remain "on" until the event
    // is <reset>.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.2
    virtual task wait_on (bit delta = 0);
        if (on) 
          begin
            if (delta)
            begin
              #0;
            end

            return;
          end
        num_waiters++;
        @on;
    endtask


    // Task -- NODOCS -- wait_off
    //
    // If the event has already triggered and is "on", this task waits for the
    // event to be turned "off" via a call to <reset>.
    //
    // If the event has not already been triggered, this task returns immediately.
    // If ~delta~ is set, the caller will be forced to wait a single delta #0
    // before returning. This prevents the caller from returning before
    // previously waiting processes have had a chance to resume.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.3
    virtual task wait_off (bit delta = 0);
        if (!on) 
          begin
            if (delta)
            begin
              #0;
            end

            return;
          end
        num_waiters++;
        @on;
    endtask


    // Task -- NODOCS -- wait_trigger
    //
    // Waits for the event to be triggered. 
    //
    // If one process calls wait_trigger in the same delta as another process
    // calls <uvm_event#(T)::trigger>, a race condition occurs. If the call to wait occurs
    // before the trigger, this method will return in this delta. If the wait
    // occurs after the trigger, this method will not return until the next
    // trigger, which may never occur and thus cause deadlock.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.4
    virtual task wait_trigger ();
        num_waiters++;
        @m_event;
    endtask


    // Task -- NODOCS -- wait_ptrigger
    //
    // Waits for a persistent trigger of the event. Unlike <wait_trigger>, this
    // views the trigger as persistent within a given time-slice and thus avoids
    // certain race conditions. If this method is called after the trigger but
    // within the same time-slice, the caller returns immediately.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.5
    virtual task wait_ptrigger ();
        if (m_event.triggered)
          begin
            return;
          end

        num_waiters++;
        @m_event;
    endtask


    // Function -- NODOCS -- get_trigger_time
    //
    // Gets the time that this event was last triggered. If the event has not been
    // triggered, or the event has been reset, then the trigger time will be 0.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.6
    virtual function time get_trigger_time ();
        return trigger_time;
    endfunction


    //-------//
    // state //
    //-------//

    // Function -- NODOCS -- is_on
    //
    // Indicates whether the event has been triggered since it was last reset. 
    //
    // A return of 1 indicates that the event has triggered.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.7
    virtual function bit is_on ();
        return (on == 1);
    endfunction


    // Function -- NODOCS -- is_off
    //
    // Indicates whether the event has been triggered or been reset.
    //
    // A return of 1 indicates that the event has not been triggered.

    virtual function bit is_off ();
        return (on == 0);
    endfunction


    // Function -- NODOCS -- reset
    //
    // Resets the event to its off state. If ~wakeup~ is set, then all processes
    // currently waiting for the event are activated before the reset.
    //
    // No callbacks are called during a reset.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.8
    virtual function void reset (bit wakeup = 0);
      event e;
      if (wakeup)
        begin
          ->m_event;
        end

      m_event = e;
      num_waiters = 0;
      on = 0;
      trigger_time = 0;
    endfunction



    //--------------//
    // waiters list //
    //--------------//

    // Function -- NODOCS -- cancel
    //
    // Decrements the number of waiters on the event. 
    //
    // This is used if a process that is waiting on an event is disabled or
    // activated by some other means.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.9
    virtual function void cancel ();
        if (num_waiters > 0)
          begin
            num_waiters--;
          end

    endfunction


    // Function -- NODOCS -- get_num_waiters
    //
    // Returns the number of processes waiting on the event.

    // @uvm-ieee 1800.2-2020 auto 10.1.1.2.10
    virtual function int get_num_waiters ();
        return num_waiters;
    endfunction


    virtual function void do_print (uvm_printer printer);
        printer.print_field_int("num_waiters", num_waiters, $bits(num_waiters), UVM_DEC, ".", "int");
        printer.print_field_int("on", on, $bits(on), UVM_BIN, ".", "bit");
        printer.print_time("trigger_time", trigger_time);
    endfunction


    virtual function void do_copy (uvm_object rhs);
        uvm_event_base e;
        super.do_copy(rhs);
        if(!$cast(e, rhs) || (e==null)) 
          begin
            return;
          end


        m_event = e.m_event;
        num_waiters = e.num_waiters;
        on = e.on;
        trigger_time = e.trigger_time;

    endfunction

endclass

// Class: uvm_event#(T)
// This is an implementation of uvm_event#(T) as described in 1800.2 with
// the addition of API described below.

// @uvm-ieee 1800.2-2020 auto 10.1.2.1
class uvm_event#(type T=uvm_object) extends uvm_event_base;

    typedef uvm_event#(T) this_type;
    typedef uvm_event_callback#(T) cb_type;

    // Type: cbs_type
    // Callback typedef for this event type.
    //
    // | typedef uvm_callbacks#(this_type, cb_type) cbs_type;
    // @uvm-contrib Potential Contribution to 1800.2
    typedef uvm_callbacks#(this_type, cb_type) cbs_type;
   
    // Not using `uvm_register_cb(this_type, cb_type)
    // so as to try and get ~slightly~ better debug
    // output for names.
    static local function bit m_register_cb();
        return cbs_type::m_register_pair("uvm_pkg::uvm_event#(T)",
                                         "uvm_pkg::uvm_event_callback#(T)"
                                        );
    endfunction : m_register_cb
    static local bit m_cb_registered = m_register_cb();
   
    `uvm_object_param_utils(this_type)

    // Better type name for debug
    virtual function string get_type_name();
        return "uvm_pkg::uvm_event#(T)";
    endfunction : get_type_name

    local T trigger_data;
    local T default_data;

    // Function -- NODOCS -- new
    //
    // Creates a new event object.

    // @uvm-ieee 1800.2-2020 auto 10.1.2.2.1
    function new (string name="");
        super.new(name);
    endfunction  

    // Function -- NODOCS -- reset
    //
    // Resets the event to its off state and clears trigger data to its default state.

    virtual function void reset (bit wakeup = 0);
        trigger_data = get_default_data();
        super.reset(wakeup);
    endfunction : reset

    // Task -- NODOCS -- wait_trigger_data
    //
    // This method calls <uvm_event_base::wait_trigger> followed by <get_trigger_data>.

    // @uvm-ieee 1800.2-2020 auto 10.1.2.2.2
    virtual task wait_trigger_data (output T data);
        wait_trigger();
        data = get_trigger_data();
    endtask


    // Task -- NODOCS -- wait_ptrigger_data
    //
    // This method calls <uvm_event_base::wait_ptrigger> followed by <get_trigger_data>.

    // @uvm-ieee 1800.2-2020 auto 10.1.2.2.3
    virtual task wait_ptrigger_data (output T data);
        wait_ptrigger();
        data = get_trigger_data();
    endtask


    //------------//
    // triggering //
    //------------//

    // Function -- NODOCS -- trigger
    //
    // Triggers the event, resuming all waiting processes.
    //
    // An optional ~data~ argument can be supplied with the enable to provide
    // trigger-specific information.

    // @uvm-ieee 1800.2-2020 auto 10.1.2.2.4
    virtual function void trigger (T data=get_default_data());
      int   skip;
      cb_type cb_q[$];
      skip=0;
      cbs_type::get_all(cb_q, this);
          
      // Call all pre_trigger, bail out after
      // if any return !0
      foreach (cb_q[i])
        begin
          skip += cb_q[i].pre_trigger(this, data);
        end

      if (skip==0) 
        begin
          on = 1;
          trigger_time = $realtime;
          trigger_data = data;
          ->m_event;
          foreach (cb_q[i])
          begin
            cb_q[i].post_trigger(this, data);
          end

          num_waiters = 0;
        end
    endfunction


    // Function -- NODOCS -- get_trigger_data
    //
    // Gets the data, if any, provided by the last call to <trigger>.

    // @uvm-ieee 1800.2-2020 auto 10.1.2.2.5
    virtual function T get_trigger_data ();
        return trigger_data;
    endfunction

        // Function -- NODOCS -- default data

        // @uvm-ieee 1800.2-2020 auto 10.1.2.2.6
        virtual function T get_default_data();
       return default_data;
    endfunction : get_default_data

        // @uvm-ieee 1800.2-2020 auto 10.1.2.2.6
        virtual function void set_default_data(T data);
       default_data = data;
    endfunction : set_default_data

    virtual function void do_print (uvm_printer printer);
       uvm_event#(uvm_object) oe;
       cb_type cb_q[$];
       
       super.do_print(printer);

       // Printing the callbacks
       cbs_type::get_all(cb_q, this);
           printer.print_array_header("callbacks", cb_q.size(), "queue");
       foreach(cb_q[e])
         begin
           printer.print_object($sformatf("[%0d]", e), cb_q[e], "[");
         end

           printer.print_array_footer(cb_q.size());
       
       if ($cast(oe, this)) 
         begin
           printer.print_object("trigger_data", oe.get_trigger_data());
         end
       else 
         begin
           uvm_event#(string) se;
           if ($cast(se, this))
           begin
             printer.print_string("trigger_data", se.get_trigger_data());
           end

         end
    endfunction
    
    virtual function void do_copy (uvm_object rhs);
       this_type e;
       cb_type cb_q[$];
       super.do_copy(rhs);
       if(!$cast(e, rhs) || (e==null)) 
         begin
           return;
         end

       trigger_data = e.trigger_data;

       begin
         // Copying the callbacks is VERY ugly
         //

         // First we retrieve any existing callbacks for this
         // instance, and delete them.  Note that this can
         // bump into Mantis 6450, which would result in
         // incorrect behavior until that mantis is fixed.
         // \todo Remove this note when 6450 is resolved.
         cbs_type::get_all(cb_q, this);
         foreach(cb_q[i])
           begin
             cbs_type::delete(this, cb_q[i]);
           end


         // We now have an empty instance queue, which we'll fill
         // using the rhs.
         cb_q.delete();
         cbs_type::get_all(cb_q, e);
         foreach(cb_q[i])
           begin
             cbs_type::add(this, cb_q[i]);
           end


       end
    endfunction

    // @uvm-compat - Added for compatibility with UVM 1.2.
    virtual function void add_callback(cb_type cb, bit append=1);
        uvm_apprepend ordering;
        ordering = (append) ? UVM_APPEND : UVM_PREPEND;
        cbs_type::add(this, cb, ordering);
    endfunction

    // @uvm-compat - Added for compatibility with UVM 1.2.
    virtual function void delete_callback(cb_type cb);
        cbs_type::delete(this, cb);
    endfunction

endclass
