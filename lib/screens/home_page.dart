import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lamlayers/screens/google_font_screen.dart';
import 'package:lamlayers/screens/my_poster_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFffc278),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 50.0.h),
              child: Container(
                height: 300.h,
                width: 300.w,
                child: ClipRRect(
                  child: Image.asset(
                    'assets/app_images/fox_background_vector_shape.png',
                    width: double.infinity,
                    fit: BoxFit.fitWidth,
                  ),
                ),
              ),
            ),
            Align(
              alignment: AlignmentGeometry.bottomCenter,
              child: Container(
                height: 550.h,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40.sp),
                    topRight: Radius.circular(40.sp),
                  ),
                ),
                child: Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.only(
                        top: 40.0.h,
                        left: 25.h,
                        right: 25.h,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,

                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MyDesignsScreen(),
  ),
);

                            },
                            child: Container(
                              height: 150.h,
                              width: 160.w,
                              decoration: BoxDecoration(
                                color: Color(0xFFFF7648),
                                borderRadius: BorderRadius.circular(20.sp),
                              ),
                              child: Stack(
                                children: [
                                  Align(
                                    alignment: AlignmentGeometry.topRight,
                                    child: Container(
                                      height: 70.h,
                                      width: 80.w,
                                      decoration: BoxDecoration(
                                        color: Color(0xFFFFC278),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.elliptical(10.w, 50.w),
                                          bottomLeft: Radius.elliptical(
                                            50.w,
                                            40.w,
                                          ),
                                          topRight: Radius.circular(20.sp),
                                        ),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          size: 35.sp,
                                          Icons.add_circle_outline_outlined,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                            
                                  Align(
                                    alignment: AlignmentGeometry.bottomLeft,
                                    child: Padding(
                                      padding: EdgeInsets.all(8.0.h),
                                      child: Text.rich(
                                        TextSpan(
                                          children: [
                                            TextSpan(
                                              text: "Create a\n",
                                              style: TextStyle(
                                                fontSize: 15.sp,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            TextSpan(
                                              text: "Poster",
                                              style: TextStyle(
                                                fontSize: 25.sp,
                                                fontFamily: 'Poppins',
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          Container(
                            height: 150.h,
                            width: 160.w,
                            decoration: BoxDecoration(
                              color: Color(0xFF8F98FF),
                              borderRadius: BorderRadius.circular(20.sp),
                            ),
                            child: Stack(
                              children: [
                                Align(
                                  alignment: AlignmentGeometry.topRight,
                                  child: Container(
                                    height: 70.h,
                                    width: 80.w,
                                    decoration: BoxDecoration(
                                      color: Color(0xFF182A88),
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.elliptical(10.w, 50.w),
                                        bottomLeft: Radius.elliptical(
                                          50.w,
                                          40.w,
                                        ),
                                        topRight: Radius.circular(20.sp),
                                      ),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        size: 35.sp,
                                        Icons.add_circle_outline_outlined,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),

                                Align(
                                  alignment: AlignmentGeometry.bottomLeft,
                                  child: Padding(
                                    padding: EdgeInsets.all(8.0.h),
                                    child: Text.rich(
                                      TextSpan(
                                        children: [
                                          TextSpan(
                                            text: "Make Your\n",
                                            style: TextStyle(
                                              fontSize: 15.sp,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                          TextSpan(
                                            text: "Scrapbook",
                                            style: TextStyle(
                                              fontSize: 25.sp,
                                              fontFamily: 'Poppins',
                                              fontWeight: FontWeight.bold,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Heading Row
                        Padding(
                          padding: EdgeInsets.only(
                            top: 20.0.h,
                            left: 25.h,
                            right: 25.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Templates",
                                style: TextStyle(
                                  fontSize: 25.sp,
                                  fontFamily: 'Poppins',
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              // Right side green button with white arrow
                              Container(
                                height: 40.h,
                                width: 40.h,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Icon(
                                  Icons.arrow_forward_ios,
                                  color: Colors.white,
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10.h),

                        // Horizontal ListView
                        SizedBox(
  height: 150.h,
  child: ListView(
    scrollDirection: Axis.horizontal,
    children: [
 SizedBox(),
    ],
  ),
)

                      ],
                    ),
                   


                    Padding(
                        padding: EdgeInsets.only(
                            top: 20.0.h,
                            left: 10.h,
                            right: 10.h,
                          ),
                      child: Container(
                        height: 100.h,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          children: [
                            Container(
                              height: 100.h,
                              width: 30.w,
                              child: RotatedBox(
                                quarterTurns: -1, // 90 degrees clockwise
                                child: Center(
                                  child: Text(
                                    "Sponsored",
                                    style: TextStyle(
                                      fontSize: 16.sp,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Container(
                              height: 100.h,
                              width: 320.w,
                              color: Colors.green,
                            ),
                          ],
                        ),
                      ),
                    ),

                  ],
                ),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: 15.0.h),
              child: Container(
                height: 400.h,
                width: 300.w,
                // color: Colors.blue,
                child: ClipRRect(
                  child: Image.asset(
                    'assets/app_images/home_fox.png',
                    width: double.infinity,
                    fit: BoxFit.fitHeight,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
