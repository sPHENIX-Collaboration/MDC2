import re, os
module_list = {}
#log_count = 0
log_count2 = 0
n = 0
os.chdir('/sphenix/sim/sim01/sphnxpro/mdc2/logs/shijing_hepmc/fm_0_20/pass3calo/log.run7')
for f_name in os.listdir('/sphenix/sim/sim01/sphnxpro/mdc2/logs/shijing_hepmc/fm_0_20/pass3calo/log.run7'):
    if f_name.endswith('.out'):
        with open(f_name,'r') as log_file:
            #log_count += 1
            log_count2 +=1
            if log_count2 == 1000:
                print ((log_count2 +n))
                log_count2 = 0
                n += 1000
            #if log_count >100:
                #break
            lines = log_file.readlines()
            for line in lines:
                if "per event" in line:
                    event_name = line.split("_TOP")
                    del event_name [1] 
                    module_name = str(event_name)[2:-2]
                    event_time = [str(s) for s in re.findall(r'-?\d+\.?\d*', line)] 
                    if "e-" in line:
                        event_time = [re.findall('[-+]?[\d]+\.?[\d]*[Ee](?:[-+]?[\d]+)?', line)]
                        
                    if "e+" in line:
                         event_time = [re.findall('[-+]?[\d]+\.?[\d]*[Ee](?:[-+]?[\d]+)?', line)]
                         
                    module_list.setdefault(module_name,[]).append(event_time)


for i in module_list:
    r = [i, module_list[i]]
    module_name = r.pop(0) + ".timing"
    e = str(r.pop(-0))
    event_time = e.replace ("[", "")
    event_time = event_time.replace ("]", "") 
    event_time = event_time.replace ("'", "")
    event_time = event_time.replace (", ", "\n")
    
    os.chdir('/sphenix/user/zpinkenburg/Calorimeter_new')
    with open(module_name, 'w') as h:
                               
        h.writelines(str(event_time))
        h.writelines('\n')
    
