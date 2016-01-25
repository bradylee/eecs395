#include <stdio.h>
#include <limits.h>

main()
{
	static const int LIMIT = 128;
	static const int LENGTH = 64;

	int r;
	int i;
	
	FILE *x_file = fopen("x.txt", "w");
	FILE *y_file = fopen("y.txt", "w");
	FILE *z_file = fopen("z.txt", "w");
	
	srand(time(NULL));
	for (i = 0; i < LENGTH; i++) 
	{
		int x = rand() % LIMIT;
		int y = rand() % LIMIT;
                int z = x + y;

		fprintf(x_file, "%02x\n", x);
		fprintf(y_file, "%02x\n", y);
		fprintf(z_file, "%02x\n", z);
	}
	
	return 0;
}
