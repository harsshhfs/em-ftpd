require 'tempfile'
require 'pg'
require 'em-ftpd'
require 'eventmachine'

class PgFTPDriver
  
attr_accessor :current_dir ,:current_dirid,:dirlis,:dirlist,:file

  def change_dir(path, &block)
   
    dirname = path.match(/([^\/.]*)$/)
   
    ndirname = "/"+dirname[0]
  case path
    
  when path then
    
  begin
       conn = connecttodb() 
       
      # puts "changing dir to : "+ndirname
       
       conn.prepare('stmt2','select name,foid from folders where name=$1 ')
    
       res = conn.exec_prepared('stmt2',[ndirname])
               
         if res.count == 1
           
           currentdir(path,res.getvalue(0,1))
                      
           #puts "Current dir is : "+current_dir
           
          # puts "Current dir id is : "+current_dirid
           yield true           
         
         else   
         
          yield false         
          
             
         end   
    
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
    when ".." then
      
      begin
       conn = connecttodb() 
       #puts "changing dir to : "+path
       
      
       conn.prepare('stmt2','select pname from folders where pname=$1 and name=$2')
    
       res = conn.exec_prepared('stmt2',[current_dirid||'1',path])
               
         if res.count == 1
           
           currentdir(path,res.getvalue(0,1))
                      
           #puts "Current dir is : "+current_dir
           
           #puts "Current dir id is : "+current_dirid
           yield true           
         
         else   
         
          yield false         
          
             
         end   
    
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
    else 
      yield true
      
    end
  end
  
  def make_dir(path, &block)
   
   newdirname = path.match(/([^\/.]*)$/)
   
   ndirname = "/"+newdirname[0]
   
    begin
      
       conn = connecttodb() 
       #puts path
      conn.prepare('stmt5','select name from folders where name=$1 and pname = $2')
       
       res1 = conn.exec_prepared('stmt5',[ndirname,current_dirid||'1'])    


       conn.prepare('stmt6','insert into folders (name,pname) values ($1,$2)')
              
       
       if res1.count == 0
       
       res = conn.exec_prepared('stmt6',[ndirname,current_dirid||'1'])    
         yield true         
       else
         yield false
       end
           
           yield true                   
         
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
  end
  
  def authenticate(user, pass, &block)
      
   begin
       conn = connecttodb() 
    
       conn.prepare('stmt1','select name,pass from test where name=$1 and pass=$2')
    
       res = conn.exec_prepared('stmt1',[user,pass])
    
           
         if res.count == 1
           yield true
           
         else                    
         
          yield false         
          
             
         end   
    
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
  end
  
  def put_file(path, data, &block)
    
    newfilename = path.match(/([^\/.]*)$/)
   
    nfilename = "/"+newfilename[0]
    
    #puts "running put file method"
    
    begin
       conn = connecttodb() 
    
       conn.prepare('stmt1','insert into files (name,fdata,pname) values ($1,$2,$3)')
    
       res = conn.exec_prepared('stmt1',[nfilename,data,current_dirid||"1"])    
          
           yield true                   
          
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
  end

  def put_file_streamed(path, data , &block)
   
    #puts "running put file stream method"
      
    newfilename = path.match(/([^\/]*)$/)
    
    nfilename = "/"+newfilename[0]
    
    begin
       conn = connecttodb() 
    
       conn.prepare('stmt1','insert into files (name,pname) values ($1,$2)')
    
       res = conn.exec_prepared('stmt1',[nfilename,current_dirid||"1"])    
                     
       conn.prepare('stmt10','update files set fdata = fdata || $1 where name = $2 and pname = $3')
       
       data.on_stream { |chunk|
         
         
         
         res1 = conn.exec_prepared('stmt10',[chunk,nfilename,current_dirid||"1"])
           
                        }  
       yield true                   
          
     rescue Exception => e
      
     puts e.message
      
     ensure
          
    end
       
  end
  
  def delete_file(path, &block)
   
   filename = path.match(/([^\/]*)$/)
    
    nfilename = "/"+filename[0]
   begin
       conn = connecttodb() 
    
       conn.prepare('stmt6','delete from files where name=$1 and pname=$2')
                  
       res4 = conn.exec_prepared('stmt6',[nfilename,current_dirid||'1'])
       
            yield true           
         
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
  end

  def delete_dir(path, &block)
    
    filename = path.match(/([^\/.]*)$/)
    
    nfilename = "/"+filename[0]
    
    begin
    
       #puts "deleting dir : "+nfilename
    
       conn = connecttodb()      
       
       conn.prepare('stmt9','select foid from folders where name=$1 and pname=$2')
    
       conn.prepare('stmt6','delete from folders where name=$1')
       
     
      
       res9 = conn.exec_prepared('stmt9',[nfilename,current_dirid||'1'])
    
       res6 = conn.exec_prepared('stmt6',[nfilename])
       
       
     #  parent_id = res9.getvalue(0,0)
       
      
          
       
           
           yield true         
          
         
    rescue Exception => e
      
      puts e.message
      
    ensure
      closedb(conn)
    
    end
    
  end
 
  def dir_contents(path, &block)
     
     
     path1 = path.match(/([^\/.]*)$/)
   
     path = "/"+path1[0]
  case path
    
  when "/" then    
     
  
  #puts "contents of : "+path
    begin
          conn = connecttodb()     
                     
          conn.prepare('stmt4','select name from folders where pname=$1')
             
          conn.prepare('stmt5', 'select name,fdata from files where pname=$1')    
                
          res2 = conn.exec_prepared('stmt4',[current_dirid||'1'])
          
          res3 = conn.exec_prepared('stmt5',[current_dirid||'1'])          
                         
              
               @dirlist = Array.new
                  k =0                         
            
               res2.each do |row1|                                 
                  val = res2.getvalue(k,0)                                 
               
                  val = val.tr('^A-Za-z0-9.', '')
               
                  @dirlist[k] = dir_item(val)                  
                                        
                  k = k+1                  
               end 
                                         
               
                res3.each_with_index do |row2,m|
                                 
                  val = res3.getvalue(m,0)                                    
                      
                    val = val.tr('^A-Za-z0-9.', '')
               
                 
                  @dirlist[k] = file_item(val,'20')
                     
                  m = m+1                      
                  k = k+1
                  
               end           
           
            yield [ *dirlist ]               
           
          
    rescue Exception => e
      
      puts e.message
      
    ensure
      
      closedb(conn)
    
    end       
     
     when path then    
    
        path =  "/"+path.tr('^A-Za-z0-9.', '')
  
     #   puts "contents of : "+path
     
     begin
          conn = connecttodb()     
                     
          conn.prepare('stmt4','select name from folders where pname=$1')
             
          conn.prepare('stmt5', 'select name,fdata from files where pname=$1')    
                
          res2 = conn.exec_prepared('stmt4',[current_dirid||'1'])
          
          res3 = conn.exec_prepared('stmt5',[current_dirid||'1'])          
                         
              
               @dirlist = Array.new
                  k =0                         
            
               res2.each do |row1|                                 
                  val = res2.getvalue(k,0)                                 
                      
                   val = val.tr('^A-Za-z0-9.', '')
                  @dirlist[k] = dir_item(val)                  
                                        
                  k = k+1                  
               end 
                             
                res3.each_with_index do |row2,m|
                                 
                  val = res3.getvalue(m,0)    
                   val = val.tr('^A-Za-z0-9.', '')                                
                      
                  @dirlist[k] = file_item(val,'60')
                     
                  m = m+1                      
                  k = k+1
                  
               end           
           
            yield [ *dirlist ]               
           
          
    rescue Exception => e
      
      puts e.message
      
    ensure
      
      closedb(conn)
    
    end       
   else
     
      yield []
      
      end        
     
  end
  
  def get_file(path, &block)
     
     #puts "file path : "+path
     
     filename = path.match(/([^\/]*)$/)
    
     nfilename = "/"+filename[0]
     
    # puts "filename "+nfilename
     
     begin
       conn = connecttodb() 
    
       conn.prepare('stmt1','select name,fdata from files where name=$1')
    
          
       res = conn.exec_prepared('stmt1',[nfilename])       
       
         if res.count == 0
           yield false
           
         else
            fdata = res.getvalue(0,1)
                               
          file = Tempfile.new('tempfile')
               
          file.write fdata 
        
          name = file.path
   
          @newfilenam = name.match(/([^\/.]*)$/)
     
          @newfilename = @newfilenam[0]
                                         
          yield file.path
           
         end
         
                              
    rescue Exception => e
      
      puts e.message
      
    ensure
      
      closedb(conn)
         
    end
    
  end
 
  def bytes(path, &block)
      
    begin
           
      yield path.size
             
    rescue Exception => e
      
      puts e.message
      
    ensure
      
      
    
    end
        
  end
  
    
private

  def dir_item(name)
        
      EM::FTPD::DirectoryItem.new(:name => name, :directory => true, :size => 0)
               
  end

  def file_item(name,bytes)
    EM::FTPD::DirectoryItem.new(:name => name, :directory => false, :size => bytes)
  
  end
  
  def connecttodb()
    PGconn.new('localhost', 5432, '', '', 'test', 'postgres', '123456') 
  end

  def closedb(conn)
    if !conn.nil?
      conn.close
    end
    
  end

  def currentdir(path="/",id="1")
  
  @current_dir = path
  @current_dirid = id
  
  
  end  

  
end

# configure the server
#driver FakeFTPDriver
#driver_args 1, 2, 3
#user "ftp"
#group "ftp"
#daemonise false
#name "fakeftp"
#pid_file "/var/run/fakeftp.pid"