#include <cmath>
#include "intersect.h"
#include "constants.h"
#include "tools.h"

/* | algo           | difficulty | */
/* |----------------+------------| */
/* | BSPherePlane   |          1 | */
/* | BBoxBBox       |          2 | */
/* | BBoxPlane      |          4 | */

// @@ TODO: test if a BSpheres intersects a plane.
//! Returns :
//   +IREJECT outside
//   -IREJECT inside
//    IINTERSECT intersect

int BSpherePlaneIntersect(const BSphere *bs, Plane *pl) {
	/* =================== PUT YOUR CODE HERE ====================== */
	float distance  =  abs(pl->signedDistance(bs->getPosition()));

	if(bs->getRadius() >= abs(distance)){
		return IINTERSECT;

	}else{
		if(pl->whichSide(bs->getPosition()) == 1){
			return IREJECT; //Lado positivo
		}
		return -IREJECT; //Lado negativo
	}

	/* =================== END YOUR CODE HERE ====================== */
}


// @@ TODO: test if two BBoxes intersect.
//! Returns :
//    IINTERSECT intersect
//    IREJECT don't intersect

int  BBoxBBoxIntersect(const BBox *bba, const BBox *bbb ) {
	/* =================== PUT YOUR CODE HERE ====================== */
		Vector3 maxBBA = bba->m_max;
		Vector3 minBBA = bba->m_min;
		Vector3 maxBBB = bbb->m_max;
		Vector3 minBBB = bbb->m_min;

		for(int i = 0; i<3; i++){
			if(minBBA[i] > maxBBB[i] || minBBB[i] > maxBBA[i]) return IREJECT;
		}
		return IINTERSECT;

	/* =================== END YOUR CODE HERE ====================== */
}

// @@ TODO: test if a BBox and a plane intersect.
//! Returns :
//   +IREJECT outside
//   -IREJECT inside
//    IINTERSECT intersect
// Don`t use bruteforce approach

int  BBoxPlaneIntersect (const BBox *theBBox, Plane *thePlane) {
	/* =================== PUT YOUR CODE HERE ====================== */
		Vector3 max = theBBox->m_max;
		Vector3 min = theBBox->m_min;
		Vector3 v1 = Vector3(min[0], min[1], min[2]);
		Vector3 v2 = Vector3(min[0], min[1], max[2]);
		Vector3 v3 = Vector3(min[0], max[1], min[2]);
		Vector3 v4 = Vector3(min[0], max[1], max[2]);
		Vector3 v5 = Vector3(max[0], min[1], min[2]);		//cojo los 8 vertices del BBOX
		Vector3 v6 = Vector3(max[0], min[1], max[2]);
		Vector3 v7 = Vector3(max[0], max[1], min[2]);
		Vector3 v8 = Vector3(max[0], max[1], max[2]);

		int contLados = 0;
		if(thePlane->whichSide(v1) == 1) contLados++;
		if(thePlane->whichSide(v2) == 1) contLados++;
		if(thePlane->whichSide(v3) == 1) contLados++;
		if(thePlane->whichSide(v4) == 1) contLados++;
		if(thePlane->whichSide(v5) == 1) contLados++;			//cuento cuantos vertices estan del lado positivo del plano
		if(thePlane->whichSide(v6) == 1) contLados++;
		if(thePlane->whichSide(v7) == 1) contLados++;
		if(thePlane->whichSide(v8) == 1) contLados++;

		if(contLados == 8) return IREJECT; 		//si todos estan del lado positivo
		if(contLados == 0) return -IREJECT;		//si todos estan del lado negativo
		return IINTERSECT;						//si hay alguno de cada lado, INTERESECCIÓN


	/* =================== END YOUR CODE HERE ====================== */
}

// Test if two BSpheres intersect.
//! Returns :
//    IREJECT don't intersect
//    IINTERSECT intersect

int BSphereBSphereIntersect(const BSphere *bsa, const BSphere *bsb ) {

	Vector3 v;
	v = bsa->m_centre - bsb->m_centre;
	float ls = v.dot(v);
	float rs = bsa->m_radius + bsb->m_radius;
	if (ls > (rs * rs)) return IREJECT; // Disjoint
	return IINTERSECT; // Intersect
}


// Test if a BSpheres intersect a BBox.
//! Returns :
//    IREJECT don't intersect
//    IINTERSECT intersect

int BSphereBBoxIntersect(const BSphere *sphere, const BBox *box) {

	float d;
	float aux;
	float r;

	r = sphere->m_radius;
	d = 0;

	aux = sphere->m_centre[0] - box->m_min[0];
	if (aux < 0) {
		if (aux < -r) return IREJECT;
		d += aux*aux;
	} else {
		aux = sphere->m_centre[0] - box->m_max[0];
		if (aux > 0) {
			if (aux > r) return IREJECT;
			d += aux*aux;
		}
	}

	aux = (sphere->m_centre[1] - box->m_min[1]);
	if (aux < 0) {
		if (aux < -r) return IREJECT;
		d += aux*aux;
	} else {
		aux = sphere->m_centre[1] - box->m_max[1];
		if (aux > 0) {
			if (aux > r) return IREJECT;
			d += aux*aux;
		}
	}

	aux = sphere->m_centre[2] - box->m_min[2];
	if (aux < 0) {
		if (aux < -r) return IREJECT;
		d += aux*aux;
	} else {
		aux = sphere->m_centre[2] - box->m_max[2];
		if (aux > 0) {
			if (aux > r) return IREJECT;
			d += aux*aux;
		}
	}
	if (d > r * r) return IREJECT;
	return IINTERSECT;
}

// Test if a Triangle intersects a ray.
//! Returns :
//    IREJECT don't intersect
//    IINTERSECT intersect

int IntersectTriangleRay(const Vector3 & P0,
						 const Vector3 & P1,
						 const Vector3 & P2,
						 const Line *l,
						 Vector3 & uvw) {
	Vector3 e1(P1 - P0);
	Vector3 e2(P2 - P0);
	Vector3 p(crossVectors(l->m_d, e2));
	float a = e1.dot(p);
	if (fabs(a) < Constants::distance_epsilon) return IREJECT;
	float f = 1.0f / a;
	// s = l->o - P0
	Vector3 s(l->m_O - P0);
	float lu = f * s.dot(p);
	if (lu < 0.0 || lu > 1.0) return IREJECT;
	Vector3 q(crossVectors(s, e1));
	float lv = f * q.dot(l->m_d);
	if (lv < 0.0 || lv > 1.0) return IREJECT;
	uvw[0] = lu;
	uvw[1] = lv;
	uvw[2] = f * e2.dot(q);
	return IINTERSECT;
}

/* IREJECT 1 */
/* IINTERSECT 0 */

const char *intersect_string(int intersect) {

	static const char *iint = "IINTERSECT";
	static const char *prej = "IREJECT";
	static const char *mrej = "-IREJECT";
	static const char *error = "IERROR";

	const char *result = error;

	switch (intersect) {
	case IINTERSECT:
		result = iint;
		break;
	case +IREJECT:
		result = prej;
		break;
	case -IREJECT:
		result = mrej;
		break;
	}
	return result;
}
