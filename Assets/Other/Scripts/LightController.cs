using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class LightController : MonoBehaviour
{
	public float speed = 2;

	void Update ()
	{
		if (Input.GetMouseButton(0))
		{
			transform.Rotate(Camera.main.transform.up,    Input.GetAxis("Mouse X") * speed, Space.World);
			transform.Rotate(Camera.main.transform.right,-Input.GetAxis("Mouse Y") * speed, Space.World);
			Cursor.lockState = CursorLockMode.Confined;
			Cursor.visible = false;
		}
		else
		{
			Cursor.lockState = CursorLockMode.None;
			Cursor.visible = true;
		}

		// Make sure these shader uniforms are set, as legacy stuff is a bit wonky in URP
		var light = GetComponent<Light>();
		Shader.SetGlobalVector("_WorldSpaceLightPos0", -light.transform.forward);
		Shader.SetGlobalVector("_LightColor0", light.color * light.intensity);
	}
}
