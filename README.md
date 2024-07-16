# ALU_Verilog
HDL description of an Arithmetic Logic Unit built using modular instances of Booth Multiplier, Carry Lookahead Adders, Restoring Divider, etc.
The ALU performs the following operations:
Operations(S):
1. A+B
2. A-B
3. AXB
4. A/B
5. A<<1
6. A>>1
7. Rotate Left A
8. Rotate Right A
9. A & B
10. A | B
11. A ^ B
12. ~(A|B)
13. ~(A&B)
14.~(A^B)
15. A>B?
16. A==B?

A sample testbench is also written to verify the correctness of the circuit description.
