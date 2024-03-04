int main() {
    char* bram0    = (char*)0x84000000;
    char* bram1    = (char*)0x85000000;
    char* flash    = (char*)0x83000000;
    char* selected = (char*)0x86000004;
    *selected = 1;
    int i = 0;
    while(i != 200*150) {
        *(bram0 + i) = *(flash + i);
        i = i+1;
    }
    *selected = 0;
}