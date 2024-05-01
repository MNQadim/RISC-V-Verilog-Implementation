module Memory(clk , memWrite, memAdr, writeData, readData);
  //inputs
  input clk,  memWrite;
  input [31:0] writeData; 
  input [31:0] memAdr;
  //outputs    
  output [31:0] readData;
  //memory declarations
  reg [7:0] memData[0:$pow(2, 16)-1];

  
  integer i;
  initial begin
    for(i = 0; i < $pow(2, 16) ; i = i+1)
      memData[i] = 8'b0; 
      $readmemb( "Memory.txt" ,memData,0 ,$pow(2, 16)-1 );   
  end


  always @(posedge clk)
    begin
          if (memWrite == 1 ) begin
              memData[memAdr] = writeData[31:24];
	            memData[memAdr+1] = writeData[23:16];
              memData[memAdr+2] = writeData[15:8];
              memData[memAdr+3] = writeData[7:0]; 
	end          
    end

  assign readData = {memData[memAdr], memData[memAdr + 1],memData[memAdr + 2], memData[memAdr+3]};
  

endmodule






