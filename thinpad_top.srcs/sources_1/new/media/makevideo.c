int main()
{
    char *bram0 = (char *)0x84000000;
    char *bram1 = (char *)0x85000000;
    char *flash = (char *)0x83000000;
    char *scale = (char *)0x86000000;
    char *selected = (char *)0x86000004;
    int num_frames = 128;
    int k = 0;
    char *real_bram;
    int real_selected = 1;
    *selected = real_selected;
    *scale = 2; // 200 * 150
    while (k != num_frames)
    {
        real_bram = (real_selected == 1) ? bram0 : bram1;
        int i = 0;
        while (i != 30000)
        {
            *(real_bram + i) = *(flash + i);
            i = i + 1;
        }
        flash = flash + 30000;
        real_selected = (real_selected == 1) ? 0 : 1;
        *selected = real_selected;
        k = k + 1;
    }
}