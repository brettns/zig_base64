# Zig Base64

As a way to learn Zig, I wanted to try implementing a Base64 decoder. I also added encoding as well, though it doesn't feel as clean as the decoding function. Maybe splitting things out more would help, but I kinda wanted it just as a simple single file for now.

It's mostly implemented through bitwise operations.

Using an unsigned 32-bit integer as a queue, we shift 6 bits at a time into it. When there are 8 or more bits in the queue, we dequeue a byte by right-shifting the oldest inserted 8 bits and casting to u8.
