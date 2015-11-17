// This example will write the input data into UDP packets
// Use Wireshark (http://www.wireshark.org) to open the pcap data file.

// compile
g++ udp_writer.cpp -o udp_writer

// run the udp test with the input text file
./udp_writer < eecs-395.txt > eecs-395.pcap